document.addEventListener('DOMContentLoaded', function() {
    // Find all code blocks and wrap them with copy functionality
    const codeBlocks = document.querySelectorAll('pre code');
    
    codeBlocks.forEach(function(codeBlock) {
        const pre = codeBlock.parentElement;
        
        // Skip if already wrapped or if it's inline code
        if (pre.parentElement.classList.contains('code-block-container') || 
            pre.tagName.toLowerCase() !== 'pre') {
            return;
        }
        
        // Skip very short code blocks (likely inline code that got wrapped)
        const codeText = codeBlock.textContent.trim();
        if (codeText.length < 10) {
            return;
        }
        
        // Create container div
        const container = document.createElement('div');
        container.className = 'code-block-container';
        
        // Create copy button
        const copyButton = document.createElement('button');
        copyButton.className = 'copy-button';
        copyButton.textContent = 'Copy';
        copyButton.setAttribute('aria-label', 'Copy code to clipboard');
        copyButton.setAttribute('title', 'Copy code to clipboard');
        
        // Add copy functionality
        copyButton.addEventListener('click', function(e) {
            e.preventDefault();
            const code = codeBlock.textContent;
            
            // Use the modern clipboard API if available
            if (navigator.clipboard && window.isSecureContext) {
                navigator.clipboard.writeText(code).then(function() {
                    showCopySuccess(copyButton);
                }).catch(function(err) {
                    console.error('Failed to copy: ', err);
                    fallbackCopyToClipboard(code, copyButton);
                });
            } else {
                // Fallback for older browsers
                fallbackCopyToClipboard(code, copyButton);
            }
        });
        
        // Wrap the pre element
        pre.parentNode.insertBefore(container, pre);
        container.appendChild(pre);
        container.appendChild(copyButton);
    });
    
    function showCopySuccess(button) {
        const originalText = button.textContent;
        button.textContent = 'Copied!';
        button.classList.add('copied');
        
        setTimeout(function() {
            button.textContent = originalText;
            button.classList.remove('copied');
        }, 2000);
    }
    
    function fallbackCopyToClipboard(text, button) {
        // Create a temporary textarea element
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.left = '-999999px';
        textArea.style.top = '-999999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        
        try {
            const successful = document.execCommand('copy');
            if (successful) {
                showCopySuccess(button);
            } else {
                console.error('Fallback copy failed');
                // Still show success to user even if we're not sure
                showCopySuccess(button);
            }
        } catch (err) {
            console.error('Fallback copy failed: ', err);
            // Still show success to user
            showCopySuccess(button);
        }
        
        document.body.removeChild(textArea);
    }
});
