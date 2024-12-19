#!/bin/bash

# Paths for source and destination directories
SRC_DIR="/test/test1/"
DEST_DIR="/test/"

# Today's date in yyyyMMdd format
TODAY=$(date +"%Y%m%d")
# Yesterday's date in yyyyMMdd format
YESTERDAY=$(date -d "yesterday" +"%Y%m%d")

# Iterate through all files in the source directory
for file in "$SRC_DIR"*; do
  # Get the filename without the directory path
  filename=$(basename "$file")
  
  # Check if the filename contains 'yyyyMMdd'
  if [[ $filename == *"yyyyMMdd"* ]]; then
    # Replace date placeholder and remove _0 or _1 suffix
    if [[ $filename == *"_0"* ]]; then
      new_filename=$(echo "$filename" | sed -E "s/yyyyMMdd/_${TODAY}/" | sed -E "s/_0//")
    elif [[ $filename == *"_1"* ]]; then
      new_filename=$(echo "$filename" | sed -E "s/yyyyMMdd/_${YESTERDAY}/" | sed -E "s/_1//")
    else
      # If neither _0 nor _1 is found, keep the filename unchanged
      new_filename="$filename"
    fi
  else
    # For files without 'yyyyMMdd', keep the original filename
    new_filename="$filename"
  fi

  # Copy the file to the destination directory with the updated name
  cp "$file" "$DEST_DIR$new_filename"
done

echo "File copying and renaming completed!"