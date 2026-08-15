/**
 * Firebase Cloud Messaging Service Worker for UniMarket.
 * This file handles incoming push notifications when the web app is in the
 * background (or closed) and displays them as system notifications.
 *
 * The Firebase SDK importScripts URL matches the version in pubspec.yaml.
 */
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Initialize Firebase with the project's public config.
// The apiKey and other values here are safe for client-side use.
firebase.initializeApp({
  apiKey: 'AIzaSyA4E5JOx7qPMSgqSAJvm1WMy-SqFOLi7Ac',
  authDomain: 'uni-market-application.firebaseapp.com',
  projectId: 'uni-market-application',
  storageBucket: 'uni-market-application.firebasestorage.app',
  messagingSenderId: '369449500544',
  appId: '1:369449500544:web:f73d51abeba66af3b506d6',
});

const messaging = firebase.messaging();

// Handle background push messages.
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message received:', payload);

  const notificationTitle =
    payload.notification?.title || payload.data?.title || 'UniMarket';
  const notificationBody =
    payload.notification?.body || payload.data?.body || '';
  const notificationIcon = '/icons/Icon-192.png';

  // Extract data for click handling.
  const type = payload.data?.type || '';
  const targetId = payload.data?.targetId || '';

  self.registration.showNotification(notificationTitle, {
    body: notificationBody,
    icon: notificationIcon,
    badge: '/icons/Icon-192.png',
    tag: 'unimarket-notification',
    data: {
      type: type,
      targetId: targetId,
      url: type === 'message'
        ? '/chat/' + targetId
        : '/',
    },
  });
});

// Handle notification click — open the appropriate screen.
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event.notification);

  event.notification.close();

  const targetUrl = event.notification.data?.url || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // If we already have a tab open, focus it and navigate.
        for (const client of clientList) {
          if (client.url.includes(self.location.origin) && 'focus' in client) {
            client.postMessage({
              type: 'notificationClick',
              data: event.notification.data,
            });
            return client.focus();
          }
        }
        // Otherwise open a new tab.
        if (clients.openWindow) {
          return clients.openWindow(targetUrl);
        }
      })
  );
});
