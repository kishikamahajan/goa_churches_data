import requests
from bs4 import BeautifulSoup
import re
import time
import pandas as pd

def get_church_links(main_url):
    """
    This function gets the links of all the links (for each church) on the main website. 
    """
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36'
    }

    response = requests.get(main_url, headers=headers)
    soup = BeautifulSoup(response.text, 'html.parser')

    # Getting the specifications of the webpage
    list_items = soup.find_all('li', class_='cat-item')

    # Extract links from the <li> items
    church_links = []
    for li in list_items:
        anchor = li.find('a', href=True)
        if anchor:
            href = anchor['href']
            # Creating a full URL 
            full_url = requests.compat.urljoin(main_url, href)
            church_links.append(full_url)

    return list(set(church_links))  # Return unique links

# Main website URL
main_website_url = "https://goanchurches.info/"  

# Get church links from the main website
church_links = get_church_links(main_website_url)

# Sleep for a while before printing to avoid overwhelming the server
time.sleep(3)

# Print the collected church links
print(church_links)

def extract_church_info(url):
    """
    This function extracts the information needed for each church.
    """
    print("entered the function") # For checking purposes only
    # Make a GET request to the website

    headers = {
    'User-Agent': 'Chrome/116.0.0.0',
    'Accept': 'text/html'
    }
    response = requests.get(url , headers = headers)

    # Parse the HTML content using BeautifulSoup
    soup = BeautifulSoup(response.text, 'html.parser')

    try:

        # Find the church name
        church_div = soup.find('div', class_ = 'main_title')
        if church_div is None:
            print(f"Error: 'main_title' div not found for URL: {url}")
            return None
        
        h1_tag = church_div.find('h1')
        if h1_tag is None:
            print(f"Error: 'h1' tag not found in 'main_title' for URL: {url}")
            return None
        # Extract the text from the h1 tag
        church_name = h1_tag.text.strip()   

        # Find the entry-content div, which contains the church information
        sections = soup.find_all('div', class_='col-md-6')
        address = "Not found"

        if sections:
            first_section = sections[0] # Get the first section

            # Find all the <p> tags
            paragraphs = first_section.find_all('p')

            # Check for paragraphs
            if paragraphs:
                # Combine text from all paragraphs into a string
                all_paragraphs_text = ' '.join(paragraph.get_text(strip=True) for paragraph in paragraphs)

                print("Combined Paragraphs Text:", all_paragraphs_text)

                # Extract the foundation year using terms like founded, built and established
                year_match = re.search(r'(?:founded|built|established).*?in.*?(\d{4})', all_paragraphs_text, re.IGNORECASE)
                year = year_match.group(1) if year_match else "Not found"
                print(year)

                # Extract the religious order if it is exactly Jesuit or Franciscan
                order_match = re.search(r'(Jesuit|Franciscan)', all_paragraphs_text, re.IGNORECASE)

                # Extracting orders other than the above two
                if order_match:
                    order = order_match.group(1).strip()
                else:
                    # Ensuring St. is not considered the end of the sentence
                    order_pattern = r'([^.!?]*?\border[s]?\b(?:(?!\.(?:\s|$)|St\.).)*(?:St\.(?:(?!\.(?:\s|$)).)*)?[.!?])'
                    order_sentence_match = re.search(order_pattern, all_paragraphs_text, re.IGNORECASE | re.DOTALL)
                    if order_sentence_match:
                        order = order_sentence_match.group(1).strip()
                    else:
                        order = "Not found"

                print(order)

                # Extract the address
                match = re.search(r'Address of\s+(.+)', all_paragraphs_text, re.IGNORECASE)
                
                if match:
                    address = match.group(1).strip()  # Extract and remove leading/trailing whitespace
                    print("Extracted Address:", address)
                else:
                    print("Address not found.")

                # Creating a dictionary to store the information
                church_info = {
                    "church_name": church_name,
                    "built_date": year,
                    "order": order,
                    "address": address
                }

                return church_info  
        
        print(f"Error: No valid church information found for URL: {url}")

    except Exception as e:
        print(f"An error occurred while processing {url}: {str(e)}")
    return None

if __name__ == "__main__":

    # Get church links from the main website
    church_links = get_church_links(main_website_url)

    # Initialize a list to hold all church data
    all_church_data = []

    # Loop through each church link and extract information
    for url in church_links:
        church_data = extract_church_info(url)
        if church_data:
            all_church_data.append(church_data)
        time.sleep(3)  

    # Convert the list of dictionaries into a pandas DataFrame
    df = pd.DataFrame(all_church_data)

    # Save the DataFrame to a CSV file
    df.to_csv('church_data.csv', index=False)
