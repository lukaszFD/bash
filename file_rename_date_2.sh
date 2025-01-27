#Explanation of Key Steps:
#1. Date Variables:
#TODAY and YESTERDAY store today's and yesterday's dates in yyyyMMdd format.
#2. Filename Processing:
#The if condition checks if the filename contains yyyyMMdd.
#The sed command replaces yyyyMMdd with the correct date and removes _0 or _1 from the filename.
#3. Copying Files:
#The cp command copies files to the destination directory with the new filename or retains the original name if no changes #are needed.



#!/bin/bash

# Paths for source and destination directories
SRC_DIR="/test/test1/"
DEST_DIR="/test/"

# Today's date in yyyyMMdd format
TODAY=$(date +"%Y%m%d")
# Yesterday's date in yyyyMMdd format
YESTERDAY=$(date -d "yesterday" +"%Y%m%d")

# Iterate through all files and directories in the source directory
for entry in "$SRC_DIR"*; do
  # Get the basename of the file or directory
  name=$(basename "$entry")

  # Check if the name contains 'yyyyMMdd'
  if [[ $name == *"yyyyMMdd"* ]]; then
    # Replace date placeholder and remove _0 or _1 suffix
    if [[ $name == *"_0"* ]]; then
      new_name=$(echo "$name" | sed -E "s/yyyyMMdd/${TODAY}/" | sed -E "s/_0//")
    elif [[ $name == *"_1"* ]]; then
      new_name=$(echo "$name" | sed -E "s/yyyyMMdd/${YESTERDAY}/" | sed -E "s/_1//")
    fi
  else
    # For names without 'yyyyMMdd', keep the original name
    new_name="$name"
  fi

  # Check if it's a file or directory and copy to the destination with the updated name
  if [[ -d "$entry" ]]; then
    cp -r "$entry" "$DEST_DIR$new_name"
  else
    cp "$entry" "$DEST_DIR$new_name"
  fi
done

echo "File copying and renaming completed!"

# Compression logic based on compression_list.csv
COMPRESSION_LIST="compression_list.csv"

while IFS="," read -r type name extension; do
  # Skip header row
  if [[ "$type" == "Type" ]]; then
    continue
  fi

  # Remove quotes from fields
  type=$(echo "$type" | tr -d '"')
  name=$(echo "$name" | tr -d '"')
  extension=$(echo "$extension" | tr -d '"')

  # Update name in memory to reflect renaming logic
  if [[ $name == *"yyyyMMdd"* ]]; then
    if [[ $name == *"_0"* ]]; then
      updated_name=$(echo "$name" | sed -E "s/yyyyMMdd/${TODAY}/" | sed -E "s/_0//")
    elif [[ $name == *"_1"* ]]; then
      updated_name=$(echo "$name" | sed -E "s/yyyyMMdd/${YESTERDAY}/" | sed -E "s/_1//")
    fi
  else
    updated_name="$name"
  fi

  # Identify the source path in DEST_DIR
  source_path="$DEST_DIR$updated_name"

  # Perform compression based on type
  if [[ "$type" == "file" && -f "$source_path" ]]; then
    zip -j "$source_path.$extension" "$source_path" && rm "$source_path"
  elif [[ "$type" == "dir" && -d "$source_path" ]]; then
    7z a "$source_path.$extension" "$source_path" && rm -r "$source_path"
  fi
done < "$COMPRESSION_LIST"

echo "Compression completed!"
