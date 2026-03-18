#!/usr/bin/env python3
"""
Transactional email sender for Jade Oracle readings.
Priority: Resend > Klaviyo > Gmail SMTP
"""

import argparse
import base64
import json
import os
import sys
import urllib.request
import urllib.error

SECRETS_DIR = os.path.expanduser("~/.openclaw/secrets")


def load_key(filename, env_var=None):
    """Load API key from secrets file or env"""
    key_file = os.path.join(SECRETS_DIR, filename)
    if os.path.exists(key_file):
        with open(key_file) as f:
            return f.read().strip()
    if env_var:
        return os.environ.get(env_var, "")
    return ""


def send_via_resend(to_email, name, subject, body_html, pdf_path=None):
    """Send email via Resend API (primary — free 3000/month)"""
    api_key = load_key("resend.key", "RESEND_API_KEY")
    if not api_key:
        raise Exception("No Resend API key (create at resend.com, save to ~/.openclaw/secrets/resend.key)")

    payload = {
        "from": "The Jade Oracle <readings@jadeoracle.co>",
        "to": [to_email],
        "subject": subject,
        "html": body_html,
    }

    if pdf_path and os.path.exists(pdf_path):
        with open(pdf_path, "rb") as f:
            pdf_b64 = base64.b64encode(f.read()).decode()
        payload["attachments"] = [{
            "filename": os.path.basename(pdf_path),
            "content": pdf_b64,
        }]

    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        "https://api.resend.com/emails",
        data=data,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST"
    )

    try:
        resp = urllib.request.urlopen(req)
        result = json.loads(resp.read().decode())
        return {"status": "sent", "provider": "resend", "id": result.get("id", "")}
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        raise Exception(f"Resend API error {e.code}: {error_body}")


def send_via_klaviyo(to_email, name, subject, body_html, pdf_path=None):
    """Send email via Klaviyo transactional API (requires paid plan)"""
    api_key = load_key("klaviyo.key", "KLAVIYO_API_KEY")
    if not api_key:
        raise Exception("No Klaviyo API key found")

    payload = {
        "data": {
            "type": "email",
            "attributes": {
                "from_email": "readings@jadeoracle.co",
                "from_name": "The Jade Oracle",
                "to": [{"email": to_email, "name": name}],
                "subject": subject,
                "html": body_html,
            }
        }
    }

    if pdf_path and os.path.exists(pdf_path):
        with open(pdf_path, "rb") as f:
            pdf_b64 = base64.b64encode(f.read()).decode()
        payload["data"]["attributes"]["attachments"] = [{
            "filename": os.path.basename(pdf_path),
            "content_type": "application/pdf",
            "data": pdf_b64
        }]

    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        "https://a.klaviyo.com/api/emails/",
        data=data,
        headers={
            "Authorization": f"Klaviyo-API-Key {api_key}",
            "Content-Type": "application/json",
            "revision": "2024-10-15",
        },
        method="POST"
    )

    try:
        resp = urllib.request.urlopen(req)
        return {"status": "sent", "provider": "klaviyo", "code": resp.status}
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        raise Exception(f"Klaviyo API error {e.code}: {error_body}")


def send_via_smtp(to_email, name, subject, body_html, pdf_path=None):
    """Fallback: send via Gmail SMTP (requires app password)"""
    import smtplib
    from email.mime.multipart import MIMEMultipart
    from email.mime.text import MIMEText
    from email.mime.application import MIMEApplication

    smtp_user = load_key("smtp.env") or os.environ.get("SMTP_USER", "")
    smtp_pass = os.environ.get("SMTP_PASS", "")

    # Parse smtp.env format
    if smtp_user and "=" in smtp_user:
        env_vars = {}
        for line in smtp_user.split("\n"):
            line = line.strip()
            if line.startswith("export "):
                line = line[7:]
            if "=" in line:
                k, v = line.split("=", 1)
                env_vars[k.strip()] = v.strip().strip('"').strip("'")
        smtp_user = env_vars.get("SMTP_USER", "")
        smtp_pass = env_vars.get("SMTP_PASS", smtp_pass)

    if not smtp_user or not smtp_pass:
        raise Exception("No SMTP credentials (save to ~/.openclaw/secrets/smtp.env)")

    msg = MIMEMultipart("alternative")
    msg["From"] = f"The Jade Oracle <{smtp_user}>"
    msg["To"] = to_email
    msg["Subject"] = subject
    msg["Reply-To"] = "readings@jadeoracle.co"
    msg.attach(MIMEText(body_html, "html"))

    if pdf_path and os.path.exists(pdf_path):
        with open(pdf_path, "rb") as f:
            pdf_att = MIMEApplication(f.read(), _subtype="pdf")
            pdf_att.add_header("Content-Disposition", "attachment",
                               filename=os.path.basename(pdf_path))
            msg.attach(pdf_att)

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(smtp_user, smtp_pass)
        server.send_message(msg)

    return {"status": "sent", "provider": "smtp"}


def build_reading_email_html(name, reading_type):
    """Build beautiful HTML email for reading delivery"""
    return f"""
    <div style="max-width:600px;margin:0 auto;font-family:'Georgia',serif;background:#1a1a2e;color:#e0e0e0;padding:40px;border-radius:12px;">
        <div style="text-align:center;margin-bottom:30px;">
            <h1 style="color:#ffd700;font-size:28px;margin:0;">The Jade Oracle</h1>
            <p style="color:#888;font-size:14px;">Ancient Wisdom, Modern Guidance</p>
        </div>
        <div style="background:#16213e;padding:30px;border-radius:8px;border-left:4px solid #ffd700;">
            <p style="font-size:18px;color:#c0c0ff;">Dear {name},</p>
            <p>Thank you for trusting The Jade Oracle with your {reading_type} reading.</p>
            <p>Your personalized reading has been carefully prepared using three ancient systems:</p>
            <ul style="color:#aaa;">
                <li><strong style="color:#ffd700;">Qi Men Dun Jia (&#22855;&#38376;&#36929;&#30002;)</strong> — Chinese cosmic divination</li>
                <li><strong style="color:#ffd700;">Western Astrology</strong> — Planetary alignments at your birth</li>
                <li><strong style="color:#ffd700;">Tarot</strong> — Archetypal energy reading</li>
            </ul>
            <p>Your full reading is attached as a PDF. Please take a quiet moment to reflect on the insights within.</p>
        </div>
        <div style="text-align:center;margin-top:30px;">
            <a href="https://jadeoracle.co" style="display:inline-block;background:#ffd700;color:#1a1a2e;padding:12px 30px;text-decoration:none;border-radius:6px;font-weight:bold;">Explore Deeper Readings</a>
        </div>
        <div style="text-align:center;margin-top:30px;color:#666;font-size:12px;">
            <p>This reading is for entertainment purposes only.</p>
            <p>&copy; The Jade Oracle | <a href="https://jadeoracle.co" style="color:#ffd700;">jadeoracle.co</a></p>
        </div>
    </div>
    """


def main():
    parser = argparse.ArgumentParser(description="Send Jade Oracle reading email")
    parser.add_argument("--to", required=True, help="Recipient email")
    parser.add_argument("--name", required=True, help="Customer name")
    parser.add_argument("--pdf", help="Path to reading PDF")
    parser.add_argument("--subject", default="Your Reading from The Jade Oracle")
    parser.add_argument("--reading-type", default="psychic", help="Reading type for email body")
    parser.add_argument("--provider", default="auto", choices=["resend", "klaviyo", "smtp", "auto"])
    args = parser.parse_args()

    html = build_reading_email_html(args.name, args.reading_type)

    if args.provider == "auto":
        providers = ["resend", "klaviyo", "smtp"]
    else:
        providers = [args.provider]

    for provider in providers:
        try:
            if provider == "resend":
                result = send_via_resend(args.to, args.name, args.subject, html, args.pdf)
            elif provider == "klaviyo":
                result = send_via_klaviyo(args.to, args.name, args.subject, html, args.pdf)
            else:
                result = send_via_smtp(args.to, args.name, args.subject, html, args.pdf)
            print(json.dumps(result))
            return 0
        except Exception as e:
            print(f"  {provider} failed: {e}", file=sys.stderr)
            continue

    print("All email providers failed", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
