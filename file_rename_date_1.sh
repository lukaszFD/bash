#!/bin/bash

# Paths for source and destination directories
SRC_DIR="/home/lukasz/Documents/file/integration_tests/"
DEST_DIR="/home/lukasz/Documents/file/shared.folders/"
OUTPUT_LIST="/home/lukasz/Documents/file/compression_list.csv"

# Today's and yesterday's date in the required formats
TODAY=$(date +"%Y%m%d")
YESTERDAY=$(date -d "yesterday" +"%Y%m%d")
MONTH_FULL=$(date +"%B")
MONTH_SHORT=$(date +"%b" | tr '[:lower:]' '[:upper:]') # Uppercase short month name
MONTH_LOCAL=$(date +"%b" | tr '[:upper:]' '[:lower:]') # Lowercase short month name

# Initialize the compression list file
echo "Type,Name,Extension" > "$OUTPUT_LIST"

# Iterate through all files in the source directory
for file in "$SRC_DIR"*; do
  # Get the filename without the directory path
  filename=$(basename "$file")
  
  # Initialize new filename
  new_filename="$filename"
  
  # Replace date placeholders and suffixes based on patterns
  if [[ $filename == *"_MMM_"* ]]; then
    new_filename=$(echo "$filename" | sed -E "s/_MMM_/_${MONTH_SHORT}_/")
    new_filename=$(echo "$new_filename" | sed -E "s/_1/_${TODAY}/; s/_0/_${YESTERDAY}/")
  elif [[ $filename == *"yyyy.MM.dd"* ]]; then
    new_filename=$(echo "$filename" | sed -E "s/yyyy\\.MM\\.dd/${TODAY//-/.}/")
    new_filename=$(echo "$new_filename" | sed -E "s/_1//; s/_0//")
  elif [[ $filename == *"_dd_MMMM_"* ]]; then
    new_filename=$(echo "$filename" | sed -E "s/dd_MMMM/${TODAY:6:2}_${MONTH_FULL}/")
    new_filename=$(echo "$new_filename" | sed -E "s/_1//; s/_0//")
  elif [[ $filename == *"_LMMM_"* ]]; then
    new_filename=$(echo "$filename" | sed -E "s/_LMMM_/_${MONTH_LOCAL}_/")
    new_filename=$(echo "$new_filename" | sed -E "s/_1/_${TODAY}/; s/_0/_${YESTERDAY}/")
  elif [[ $filename == *"_MMMMyyyy_"* ]]; then
    new_filename=$(echo "$filename" | sed -E "s/MMMMyyyy/${MONTH_FULL}${TODAY:0:4}/")
    new_filename=$(echo "$new_filename" | sed -E "s/_1//; s/_0//")
  elif [[ $filename == *"yyyyMMdd"* ]]; then
    new_filename=$(echo "$filename" | sed -E "s/yyyyMMdd/${TODAY}/")
    new_filename=$(echo "$new_filename" | sed -E "s/_1//; s/_0//")
  fi

  # Copy the file to the destination directory with the updated name
  cp "$file" "$DEST_DIR$new_filename"
done

# Add directories or files to the compression list
for item in "$DEST_DIR"*; do
  # Get the basename without the directory path
  base_name=$(basename "$item")
  
  if [[ -d $item ]]; then
    # Compress directories
    echo "\"dir\",\"$base_name\",\"7z\"" >> "$OUTPUT_LIST"
    7z a "${item}.7z" "$item" >/dev/null
  elif [[ -f $item ]]; then
    # Compress files
    echo "\"file\",\"$base_name\",\"zip\"" >> "$OUTPUT_LIST"
    zip -j "${item}.zip" "$item" >/dev/null
  fi
done

echo "File renaming, copying, and compression completed!"
