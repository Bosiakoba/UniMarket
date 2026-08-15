# UniMarket Web Deployment Guide

This guide covers deploying UniMarket to Vercel with responsive design for both desktop and mobile.

## Prerequisites

- Flutter SDK installed (3.11.3 or higher)
- Node.js and npm installed
- Vercel account
- Git repository (GitHub, GitLab, or Bitbucket)

## Local Development

### Running the Web App Locally

```bash
cd unimarket
flutter pub get
flutter run -d chrome
```

### Building for Web

```bash
flutter build web --release
```

The build output will be in the `build/web` directory.

**IMPORTANT**: Since Vercel doesn't have Flutter installed, you must build locally and commit the `build/web` directory to your repository.

## Responsive Design Features

The web application is configured to be fully responsive:

- **Viewport Configuration**: Optimized for all screen sizes with proper scaling
- **Orientation Support**: Works in both portrait and landscape on web
- **Touch-Friendly**: Optimized for both mouse and touch interactions
- **Mobile-First Design**: Adapts seamlessly from mobile to desktop
- **PWA Support**: Can be installed as a progressive web app

## Vercel Deployment

### Deployment Strategy

Since Vercel doesn't have Flutter installed on build machines, we use a **static file deployment** approach:

1. Build the Flutter web app locally
2. Commit the `build/web` directory to git
3. Vercel serves the pre-built static files

### Step-by-Step Deployment

1. **Build the web app locally**:
```bash
cd unimarket
flutter build web --release
```

2. **Commit the build output**:
```bash
git add build/web
git commit -m "Build web app for deployment"
git push
```

3. **Deploy via Vercel**:
   - Option A: Push to GitHub - Vercel auto-deploys
   - Option B: Use Vercel CLI: `vercel --prod`

### Option 1: Deploy via Vercel CLI

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Login to Vercel:
```bash
vercel login
```

3. Build and deploy:
```bash
cd unimarket
flutter build web --release
git add build/web
git commit -m "Build web"
vercel --prod
```

### Option 2: Deploy via Vercel Dashboard

1. Push your code to a Git repository
2. Go to [vercel.com](https://vercel.com)
3. Click "Add New Project"
4. Import your repository
5. Configure the project:
   - **Framework Preset**: Other
   - **Root Directory**: `unimarket`
   - **Output Directory**: `build/web`
   - **Build Command**: (leave empty - we build locally)
6. Click "Deploy"

### Option 3: Deploy with GitHub Integration

1. Connect your GitHub repository to Vercel
2. Vercel will automatically detect the `vercel.json` configuration
3. Configure environment variables if needed
4. Deploy on push to main branch (after building locally)

## Vercel Configuration

The `vercel.json` file includes:

- **Output Directory**: Points to `build/web` for static files
- **Security Headers**: X-Content-Type-Options, X-Frame-Options, X-XSS-Protection
- **Caching Strategy**: Long-term caching for static assets
- **SPA Routing**: All routes redirect to index.html for client-side routing

## Environment Variables

If you need environment variables for your web build:

1. Go to your Vercel project settings
2. Navigate to "Environment Variables"
3. Add your variables (e.g., Firebase config)
4. Redeploy to apply changes

## Performance Optimization

The web build is optimized for performance:

- **Asset Caching**: Static assets cached for 1 year
- **Code Splitting**: Flutter automatically splits code
- **Tree Shaking**: Unused code is removed
- **Compression**: Vercel automatically compresses assets

## SEO and Social Sharing

The web app includes:

- **Meta Tags**: Proper description, keywords, and author tags
- **Open Graph**: Facebook and social media sharing
- **Twitter Cards**: Optimized for Twitter sharing
- **Manifest**: PWA manifest for installation

## Testing

### Test Responsive Design

1. Open Chrome DevTools (F12)
2. Toggle device toolbar (Ctrl+Shift+M)
3. Test different device presets:
   - iPhone 12 Pro
   - iPad
   - Desktop (1920x1080)
   - Mobile (375x667)

### Test PWA Installation

1. Open the app in Chrome
2. Look for the install icon in the address bar
3. Click to install as a PWA

## Troubleshooting

### Build Fails Locally

If the local build fails:

1. Ensure Flutter is installed and in PATH
2. Run `flutter doctor` to check dependencies
3. Update Flutter: `flutter upgrade`
4. Clean build: `flutter clean`

### Vercel Shows 404

If Vercel shows 404:

1. Ensure `build/web` directory is committed to git
2. Check that `vercel.json` has correct `outputDirectory`
3. Verify the build completed successfully locally
4. Check Vercel deployment logs

### Routing Issues

If routes don't work:

1. Check `vercel.json` rewrites configuration
2. Ensure client-side routing is properly configured
3. Test with `flutter run -d chrome` first

### Firebase Issues

If Firebase doesn't initialize:

1. Ensure `firebase_options.dart` is included
2. Check Firebase console for web app configuration
3. Verify environment variables are set in Vercel

## Continuous Deployment Workflow

Since we build locally, the workflow is:

1. Make code changes
2. Build locally: `flutter build web --release`
3. Commit build output: `git add build/web && git commit`
4. Push to GitHub: `git push`
5. Vercel automatically deploys

## Custom Domain

To add a custom domain:

1. Go to Vercel project settings
2. Navigate to "Domains"
3. Add your domain
4. Update DNS records as instructed

## Monitoring

Vercel provides:

- **Analytics**: Page views, visitors, and performance
- **Logs**: Real-time logs for debugging
- **Speed Insights**: Core Web Vitals and performance metrics
- **Error Tracking**: Automatic error monitoring

## Support

For issues with:
- **Flutter Web**: [Flutter Web Documentation](https://flutter.dev/web)
- **Vercel**: [Vercel Documentation](https://vercel.com/docs)
- **UniMarket**: Check the project repository

## Additional Resources

- [Flutter Web Performance](https://flutter.dev/docs/perf/web-performance)
- [Vercel Static Files](https://vercel.com/docs/deployments/overview)
- [PWA Best Practices](https://web.dev/progressive-web-apps/)
