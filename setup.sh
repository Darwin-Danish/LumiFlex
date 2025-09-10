#!/bin/bash
set -e

PROJECT_NAME="myproject"                     # Change this
GIT_REPO="https://github.com/username/repo"  # Change this
INSTALL_DIR="/home/pi/$PROJECT_NAME"
SERVICE_FILE="/etc/systemd/system/$PROJECT_NAME.service"
MAIN_FILE="main.py"                          # Change if different

echo "🔄 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing dependencies..."
sudo apt install -y python3 python3-pip git

echo "📂 Setting up project directory..."
if [ ! -d "$INSTALL_DIR" ]; then
    git clone "$GIT_REPO" "$INSTALL_DIR"
else
    cd "$INSTALL_DIR"
    git pull origin main
fi

cd "$INSTALL_DIR"
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
fi

echo "⚙️ Creating run script..."
cat <<EOF > $INSTALL_DIR/run.sh
#!/bin/bash
cd $INSTALL_DIR
echo "🔄 Pulling latest code..."
git reset --hard
git pull origin main

if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
fi

echo "🚀 Starting project..."
exec python3 $MAIN_FILE
EOF
chmod +x $INSTALL_DIR/run.sh

echo "⚙️ Creating systemd service..."
cat <<EOF | sudo tee $SERVICE_FILE
[Unit]
Description=$PROJECT_NAME Auto-Run
After=network.target

[Service]
ExecStart=$INSTALL_DIR/run.sh
WorkingDirectory=$INSTALL_DIR
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable $PROJECT_NAME
sudo systemctl start $PROJECT_NAME

echo "✅ Setup complete! Your project will auto-update and auto-start on boot."
