# Mail Sending Problem Solutions

Universal scripts for solving email delivery issues with Postfix when certain domains block direct SMTP connections.

## 🚀 Solved Problems

1. **Blocked port 25** - ISP blocks outgoing SMTP traffic
2. **Gmail restrictions** - IP address not authorized for direct sending
3. **Configuration errors** - Duplicate SSL certificates in Postfix

## 📦 Contents

### Diagnostic Scripts
- `fix_postfix.sh` - Fix Postfix configuration (certificates)
- `clean_queue.sh` - Clean mail queue
- `force_clean.sh` - Force clean all messages

### SSH Tunnel Solution
- `setup_smtp_tunnel.sh` - Create SSH tunnel for SMTP
- `configure_postfix_tunnel.sh` - Configure Postfix for tunnel
- `permanent_tunnel_setup.sh` - Systemd service for permanent tunnel

### Gmail Solution
- `gmail_solutions.sh` - Overview of Gmail solutions
- `setup_gmail_relay.sh` - Setup relay through SSH tunnel

## 🛠️ Usage

1. **Replace placeholders in scripts:**
   - `remote-server` → your relay server hostname
   - `your-domain.example.com` → your domain
   - `user@` → your email addresses

2. **Diagnose the problem**
   ```bash
   tail -f /var/log/mail.log
   mailq
   ```

3. **Create SSH tunnel**
   ```bash
   ./setup_smtp_tunnel.sh
   ./configure_postfix_tunnel.sh
   ```

4. **Gmail solution**
   ```bash
   ./setup_gmail_relay.sh
   ```

## 📋 Requirements

- Linux server with Postfix
- SSH access to relay server
- sudo permissions for configuration

## 🔧 Tested on

- Ubuntu 24.04 LTS
- Postfix 3.8
- ISP blocking port 25

## 📝 License

These scripts are freely available for solving similar problems.
