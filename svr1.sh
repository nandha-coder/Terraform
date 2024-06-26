#!/bin/bash
sudo yum install httpd -y
sudo systemctl enable httpd
sudo systemctl restart httpd


# Create a simple HTML file with the portfolio content and display the images
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>My Portfolio</title>
  <style>
    /* Add animation and styling for the text */
    @keyframes colorChange {
      0% { color: red; }
      50% { color: green; }
      100% { color: blue; }
    }
    h1 {
      animation: colorChange 2s infinite;
    }
  </style>
</head>
<body>
  <h1>Terraform Project Server 1</h1>
  <h2>Instance ID: <span style="color:green">WebServer 1</span></h2>
  <p>If you see this message Application works fine in WebServer 1</p>
  
</body>
</html>
EOF

# Restart Apache and enable it on boot
sudo systemctl restart httpd
