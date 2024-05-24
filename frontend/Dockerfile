# Use the official Flutter image
FROM cirrusci/flutter:stable

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Build the Flutter web application
RUN flutter build web

# Use Nginx to serve the built Flutter web app
FROM nginx:alpine
COPY --from=0 /app/build/web /usr/share/nginx/html
