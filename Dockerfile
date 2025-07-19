# Use a lightweight Nginx image
FROM nginx:alpine

# Copy index.html to nginx's default html folder
COPY index.html /usr/share/nginx/html/index.html

# Expose default Nginx port
EXPOSE 80

# Nginx will run automatically when the container starts

