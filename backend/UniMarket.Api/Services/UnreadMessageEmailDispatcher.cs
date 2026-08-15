using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using UniMarket.Api.Data;

namespace UniMarket.Api.Services;

public class UnreadMessageEmailDispatcher(
    IServiceScopeFactory scopeFactory,
    ILogger<UnreadMessageEmailDispatcher> logger)
{
    public void EnqueueDelayedEmail(string chatId, string messageId, string recipientId)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                // Wait for 3 minutes before checking if the message remains unread
                await Task.Delay(TimeSpan.FromMinutes(3));

                await using var scope = scopeFactory.CreateAsyncScope();
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                var emailService = scope.ServiceProvider.GetRequiredService<ResendEmailService>();

                var chat = await db.Chats.FindAsync(chatId);
                if (chat == null) return;

                var message = await db.Messages.FindAsync(messageId);
                if (message == null) return;

                // Check if recipient has read the chat since this message was sent
                var isRecipientBuyer = chat.BuyerId == recipientId;
                var lastReadAt = isRecipientBuyer ? chat.BuyerLastReadAt : chat.SellerLastReadAt;

                if (lastReadAt.HasValue && lastReadAt.Value >= message.SentAt)
                {
                    // Recipient has already read the thread, skip email
                    return;
                }

                // Check if there is any newer unread message from the same sender in this chat.
                // If there is, let the newer one trigger the email instead.
                var hasNewerMessage = await db.Messages.AnyAsync(
                    m => m.ChatId == chatId && m.SenderId == message.SenderId && m.SentAt > message.SentAt);

                if (hasNewerMessage)
                {
                    return;
                }

                var sender = await db.Users.FindAsync(message.SenderId);
                var recipient = await db.Users.FindAsync(recipientId);

                if (recipient != null)
                {
                    var senderName = sender?.FullName ?? "Someone";
                    var contentSummary = message.MessageType == "listing_inquiry" 
                        ? "Shared a listing inquiry" 
                        : message.Content;

                    await emailService.SendUnreadMessageAlertEmailAsync(
                        recipient.Email,
                        recipient.FullName,
                        senderName,
                        contentSummary,
                        chatId,
                        CancellationToken.None);
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to deliver delayed unread message email for Chat: {ChatId}, Message: {MessageId}.", chatId, messageId);
            }
        });
    }
}
