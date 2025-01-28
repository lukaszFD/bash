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

# Today's month in MMM format (uppercase)
TODAY_MMM=$(date +"%b" | tr '[:lower:]' '[:upper:]')
# Today's year
TODAY_YEAR=$(date +"%Y")

# Calculate the previous month and adjust the year if needed
PREVIOUS_MONTH=$(date -d "$(date +%Y-%m-15) -1 month" +"%b" | tr '[:lower:]' '[:upper:]')
PREVIOUS_MONTH_YEAR=$(date -d "$(date +%Y-%m-15) -1 month" +"%Y")

# Set YESTERDAY_MMM and YESTERDAY_YEAR
YESTERDAY_MMM=$PREVIOUS_MONTH
YESTERDAY_YEAR=$PREVIOUS_MONTH_YEAR

# Create unique log file name
LOG_FILE="file_rename_$(date +"%Y%m%d%H%M%S%3N").log"
LOG_PATH="$DEST_DIR$LOG_FILE"

# Log a message to the log file
log_message() {
  local level="$1"
  local message="$2"
  echo "[$(date +"%Y-%m-%d %H:%M:%S.%3N")] [$level] $message" >> "$LOG_PATH"
}

log_message "INFO" "Script execution started."

# Iterate through all files and directories in the source directory
for entry in "$SRC_DIR"*; do
  name=$(basename "$entry")

  if [[ $name == *"yyyyMMdd"* ]]; then
    if [[ $name == *"_0"* ]]; then
      new_name=$(echo "$name" | sed -E "s/yyyyMMdd/${TODAY}/" | sed -E "s/_0//")
    elif [[ $name == *"_1"* ]]; then
      new_name=$(echo "$name" | sed -E "s/yyyyMMdd/${YESTERDAY}/" | sed -E "s/_1//")
    fi
  elif [[ $name == *"Test yyyy.MM.dd_0.xlsx" ]]; then
    new_name=$(echo "$name" | sed -E "s/Test yyyy\.MM\.dd/${TODAY}/" | sed -E "s/_0//")
  elif [[ $name == *"Test yyyy.MM.dd_1.xlsx" ]]; then
    new_name=$(echo "$name" | sed -E "s/Test yyyy\.MM\.dd/${YESTERDAY}/" | sed -E "s/_1//")
  elif [[ $name == *"Test_MMM_yyyy_0.xlsx" ]]; then
    new_name=$(echo "$name" | sed -E "s/Test_MMM_yyyy/Test_${TODAY_MMM}_${TODAY_YEAR}/" | sed -E "s/_0//")
  elif [[ $name == *"Test_MMM_yyyy_1.xlsx" ]]; then
    new_name=$(echo "$name" | sed -E "s/Test_MMM_yyyy/Test_${YESTERDAY_MMM}_${YESTERDAY_YEAR}/" | sed -E "s/_1//")
  else
    new_name="$name"
  fi

  if [[ -d "$entry" ]]; then
    cp -r "$entry" "$DEST_DIR$new_name"
    if [[ $? -eq 0 ]]; then
      log_message "INFO" "Directory '$entry' copied to '$DEST_DIR$new_name'."
    else
      log_message "ERROR" "Failed to copy directory '$entry' to '$DEST_DIR$new_name'."
    fi
  else
    cp "$entry" "$DEST_DIR$new_name"
    if [[ $? -eq 0 ]]; then
      log_message "INFO" "File '$entry' copied to '$DEST_DIR$new_name'."
    else
      log_message "ERROR" "Failed to copy file '$entry' to '$DEST_DIR$new_name'."
    fi
  fi

  log_message "INFO" "Processing complete for: $entry."
done

# Compression logic based on compression_list.csv
COMPRESSION_LIST="compression_list.csv"

while IFS="," read -r type name extension; do
  if [[ "$type" == "Type" ]]; then
    continue
  fi

  type=$(echo "$type" | tr -d '"')
  name=$(echo "$name" | tr -d '"')
  extension=$(echo "$extension" | tr -d '"')

  if [[ $name == *"yyyyMMdd"* ]]; then
    if [[ $name == *"_0"* ]]; then
      updated_name=$(echo "$name" | sed -E "s/yyyyMMdd/${TODAY}/" | sed -E "s/_0//")
    elif [[ $name == *"_1"* ]]; then
      updated_name=$(echo "$name" | sed -E "s/yyyyMMdd/${YESTERDAY}/" | sed -E "s/_1//")
    fi
  else
    updated_name="$name"
  fi

  source_path="$DEST_DIR$updated_name"

  if [[ "$type" == "file" && -f "$source_path" ]]; then
    base_name=$(basename "$source_path" | sed -E 's/\.[a-zA-Z0-9]+$//')
    zip -j "$DEST_DIR${base_name}.$extension" "$source_path" && rm "$source_path"
    if [[ $? -eq 0 ]]; then
      log_message "INFO" "File '$source_path' compressed to '$DEST_DIR${base_name}.$extension'."
    else
      log_message "ERROR" "Failed to compress file '$source_path'."
    fi
  elif [[ "$type" == "dir" && -d "$source_path" ]]; then
    7z a "$source_path.$extension" "$source_path" && rm -r "$source_path"
    if [[ $? -eq 0 ]]; then
      log_message "INFO" "Directory '$source_path' compressed to '$source_path.$extension'."
    else
      log_message "ERROR" "Failed to compress directory '$source_path'."
    fi
  fi

done < "$COMPRESSION_LIST"

log_message "INFO" "Compression completed."
log_message "INFO" "Script execution completed."
