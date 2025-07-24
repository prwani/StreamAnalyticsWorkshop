# Copy Button Feature

This documentation describes the copy button functionality added to all code blocks in the Stream Analytics Workshop lab files.

## Overview

A copy button has been added to the top-right corner of all code blocks in the lab files. This allows users to easily copy code snippets for use in their own Azure Stream Analytics implementations.

## Features

- **Automatic Detection**: Copy buttons are automatically added to all `<pre><code>` blocks
- **Visual Feedback**: Button changes to "Copied! ✓" when clicked with green background
- **Cross-browser Support**: Works with modern browsers using Clipboard API and falls back to older methods
- **Mobile Responsive**: Button size and positioning adapt to mobile screens
- **Accessibility**: Proper ARIA labels and keyboard navigation support

## Implementation Details

The copy functionality consists of three main components:

### 1. CSS Styling (`assets/css/style.scss`)
- Positions copy buttons absolutely in the top-right corner
- Provides hover and active states
- Ensures proper spacing so code doesn't overlap with buttons
- Responsive design for mobile devices

### 2. JavaScript Logic (`assets/js/copy-code.js`)
- Automatically wraps code blocks with container divs
- Creates copy buttons dynamically
- Handles clipboard operations with fallback support
- Provides visual feedback when copying succeeds

### 3. Layout Integration (`_layouts/default.html`)
- Includes the JavaScript file in all pages
- Ensures copy functionality is available site-wide

## Browser Support

- **Modern browsers**: Uses Clipboard API for secure copying
- **Older browsers**: Falls back to `document.execCommand('copy')`
- **Mobile devices**: Fully supported with responsive design

## Code Block Types Supported

The copy functionality works with all code block types used in the labs:
- SQL queries (`sql`)
- PowerShell scripts (`powershell`)
- JSON configurations (`json`)
- Bash commands (`bash`)
- Plain text code blocks

## Exclusions

Copy buttons are **not** added to:
- Inline code spans (e.g., `SELECT *`)
- Very short code blocks (less than 10 characters)
- Code blocks that are already wrapped

## Testing

A test file (`test-copy.html`) has been created to verify the functionality works correctly across different code block types.

## Maintenance

The copy functionality is self-contained and requires no ongoing maintenance. The JavaScript automatically handles all code blocks on page load, making it compatible with any new lab files that are added.
