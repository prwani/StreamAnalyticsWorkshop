# Publishing to GitHub Pages

This guide will help you publish the Azure Stream Analytics Workshop to GitHub Pages.

## Prerequisites

1. A GitHub account
2. Git installed on your local machine
3. Basic knowledge of Git operations

## Steps to Publish

### 1. Create a GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click **"New repository"** or the **"+"** button
3. Name your repository (e.g., `StreamAnalyticsWorkshop`)
4. Make it **Public** (required for free GitHub Pages)
5. **Do NOT** initialize with README, .gitignore, or license (we already have these)
6. Click **"Create repository"**

### 2. Push Your Workshop to GitHub

Open a terminal/command prompt in your workshop directory and run:

```bash
# Initialize Git repository
git init

# Add all files
git add .

# Make your first commit
git commit -m "Initial commit: Azure Stream Analytics Workshop"

# Add your GitHub repository as remote (replace with your username/repo)
git remote add origin https://github.com/prwani/StreamAnalyticsWorkshop.git

# Push to GitHub
git push -u origin main
```

### 3. Enable GitHub Pages

1. Go to your repository on GitHub
2. Click **Settings** tab
3. Scroll down to **Pages** section (left sidebar)
4. Under **Source**, select **"GitHub Actions"**
5. The site will automatically build and deploy

### 4. Access Your Published Workshop

After a few minutes, your workshop will be available at:
```
https://YOURUSERNAME.github.io/StreamAnalyticsWorkshop
```

## Customization Options

### Update the Site URL
1. Edit `README.md` and replace the placeholder URL with your actual GitHub Pages URL
2. Update `_config.yml` if you want to customize the base URL

### Custom Domain (Optional)
If you have a custom domain:
1. Add a `CNAME` file with your domain name
2. Configure DNS settings to point to GitHub Pages
3. Update repository Settings > Pages > Custom domain

### Theme Customization
- Modify `assets/css/style.scss` for custom styling
- Edit `_layouts/default.html` for layout changes
- Update `_config.yml` for site configuration

## Updating Content

To update your workshop:
1. Make changes to your local files
2. Commit and push changes:
   ```bash
   git add .
   git commit -m "Update workshop content"
   git push
   ```
3. GitHub Actions will automatically rebuild and deploy

## Troubleshooting

### Build Failures
- Check the **Actions** tab in your GitHub repository
- Common issues:
  - Missing front matter in markdown files
  - Invalid YAML in `_config.yml`
  - Broken links between pages

### Local Testing
To test locally before pushing:
```bash
# Install dependencies
bundle install

# Serve locally
bundle exec jekyll serve

# View at http://localhost:4000
```

## Features Added for GitHub Pages

✅ **Jekyll Configuration** (`_config.yml`)
✅ **Custom Styling** (`assets/css/style.scss`)
✅ **Navigation Layout** (`_layouts/default.html`)
✅ **Auto-deployment** (`.github/workflows/pages.yml`)
✅ **SEO Optimization** (Jekyll SEO plugin)
✅ **Responsive Design** (Mobile-friendly)
✅ **Workshop Navigation** (Sidebar with all labs)

Your workshop is now ready for GitHub Pages! 🚀
