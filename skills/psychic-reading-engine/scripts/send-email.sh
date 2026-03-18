#!/bin/bash
#
# Email Service Integration for Psychic Readings
# Supports SendGrid, Mailgun, and AWS SES
#
# Usage:
#   send-email.sh --to "customer@email.com" --pdf "/path/to/reading.pdf" --name "Customer Name"
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
TO=""
PDF_PATH=""
CUSTOMER_NAME=""
FROM_EMAIL="support@jadeoracle.com"
SUBJECT=""
EMAIL_SERVICE="sendgrid"  # Default to SendGrid

while [[ $# -gt 0 ]]; do
    case "$1" in
        --to) TO="$2"; shift 2 ;;
        --pdf) PDF_PATH="$2"; shift 2 ;;
        --name) CUSTOMER_NAME="$2"; shift 2 ;;
        --from) FROM_EMAIL="$2"; shift 2 ;;
        --subject) SUBJECT="$2"; shift 2 ;;
        --service) EMAIL_SERVICE="$2"; shift 2 ;;
        --help) echo "Usage: $0 --to EMAIL --pdf PATH --name NAME [--subject SUBJECT] [--from EMAIL] [--service sendgrid|mailgun|ses]"
                exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Validate required arguments
if [ -z "$TO" ] || [ -z "$PDF_PATH" ] || [ -z "$CUSTOMER_NAME" ]; then
    echo "❌ Missing required arguments"
    echo "Usage: $0 --to EMAIL --pdf PATH --name NAME"
    exit 1
fi

# Set default subject
if [ -z "$SUBJECT" ]; then
    SUBJECT="Your Psychic Reading from Jade Oracle"
fi

# Detect available email services
has_sendgrid=false
has_mailgun=false
has_ses=false

if command -v sendgrid &> /dev/null; then has_sendgrid=true; fi
if command -v mailgun &> /dev/null; then has_mailgun=true; fi
if [ -n "$AWS_SES_ACCESS_KEY_ID" ] && [ -n "$AWS_SES_SECRET_ACCESS_KEY" ]; then has_ses=true; fi

# Select email service
case "$EMAIL_SERVICE" in
    sendgrid)
        if [ "$has_sendgrid" = false ]; then
            echo "❌ SendGrid CLI not found"
            echo "   Install with: brew install sendgrid/sendgrid-cli/sendgrid"
            exit 1
        fi

        if [ -z "$SENDGRID_API_KEY" ]; then
            echo "❌ SENDGRID_API_KEY not set"
            exit 1
        fi

        # Send with SendGrid
        if command -v sendgrid &> /dev/null; then
            export SENDGRID_API_KEY
            sendgrid mail send \
                --from "$FROM_EMAIL" \
                --to "$TO" \
                --subject "$SUBJECT" \
                --attach "$PDF_PATH" \
                --text "Dear $CUSTOMER_NAME,

Thank you for your order with Jade Oracle. Your personalized psychic reading has been generated and is attached to this email.

We hope this reading provides guidance and insight for your journey ahead.

Best regards,
The Jade Oracle Team"
            echo "✅ Email sent via SendGrid to $TO"
            exit 0
        else
            echo "❌ SendGrid CLI not found"
            echo "   Install with: brew install sendgrid/sendgrid-cli/sendgrid"
            exit 1
        fi
        ;;

    mailgun)
        if [ "$has_mailgun" = false ]; then
            echo "❌ Mailgun CLI not found"
            exit 1
        fi

        if [ -z "$MAILGUN_API_KEY" ] || [ -z "$MAILGUN_DOMAIN" ]; then
            echo "❌ MAILGUN_API_KEY or MAILGUN_DOMAIN not set"
            exit 1
        fi

        # Send with Mailgun
        if command -v mailgun &> /dev/null; then
            export MAILGUN_API_KEY MAILGUN_DOMAIN
            mailgun send \
                --from "$FROM_EMAIL" \
                --to "$TO" \
                --subject "$SUBJECT" \
                --attach "$PDF_PATH" \
                --text "Dear $CUSTOMER_NAME,

Thank you for your order with Jade Oracle. Your personalized psychic reading has been generated and is attached to this email.

We hope this reading provides guidance and insight for your journey ahead.

Best regards,
The Jade Oracle Team"
            echo "✅ Email sent via Mailgun to $TO"
            exit 0
        else
            echo "❌ Mailgun CLI not found"
            exit 1
        fi
        ;;

    ses)
        if [ "$has_ses" = false ]; then
            echo "❌ AWS SES credentials not found"
            echo "   Set: AWS_SES_ACCESS_KEY_ID and AWS_SES_SECRET_ACCESS_KEY"
            exit 1
        fi

        # Send with AWS SES
        if command -v aws &> /dev/null; then
            aws ses send-email \
                --from "$FROM_EMAIL" \
                --to "$TO" \
                --subject "$SUBJECT" \
                --text "Dear $CUSTOMER_NAME,

Thank you for your order with Jade Oracle. Your personalized psychic reading has been generated and is attached to this email.

We hope this reading provides guidance and insight for your journey ahead.

Best regards,
The Jade Oracle Team" \
                --source-arn "arn:aws:ses:$AWS_REGION:$AWS_ACCOUNT_ID:identity/$FROM_EMAIL" \
                --attachments fileb://"$PDF_PATH"
            echo "✅ Email sent via AWS SES to $TO"
            exit 0
        else
            echo "❌ AWS CLI not found"
            echo "   Install with: brew install awscli"
            exit 1
        fi
        ;;

    *)
        echo "❌ Unknown email service: $EMAIL_SERVICE"
        echo "   Available: sendgrid, mailgun, ses"
        exit 1
        ;;
esac