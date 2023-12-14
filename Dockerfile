# Use the official Ubuntu base image
FROM ubuntu:latest

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install necessary dependencies
RUN apt-get update && apt-get install -y \
    r-base \
    pandoc \
    texlive \
    && rm -rf /var/lib/apt/lists/*

# Install the Quarto package for R
RUN R -e "install.packages('quarto', repos='http://cran.rstudio.com/')"

# Set the working directory
WORKDIR /app

# Copy the local directory into the container
COPY . /app

# Default command to run when the container starts
CMD ["R"]

# Example: To knit a Quarto file named "example.qmd" to HTML, use the following command:
# docker run -v $(pwd):/app myquartocontainer R -e "quarto::render('example.qmd', output_format = 'html_document')"

