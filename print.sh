#!/bin/bash

QUEUE_FILE="print_queue.txt"
LOG_FILE="print_log.txt"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize files
touch "$QUEUE_FILE" "$LOG_FILE"

# ========= MENUS =========
main_menu() {
    echo -e "${YELLOW}======== Printing Management System ========${NC}"
    echo "1. Login as Admin"
    echo "2. Login as User"
    echo "3. Exit"
    echo -e "${YELLOW}===========================================${NC}"
}

admin_menu() {
    echo -e "${BLUE}\n===== ADMIN PANEL =====${NC}"
    echo "1. View Print Queue"
    echo "2. Cancel Print Job"
    echo "3. Mark Job as Printed"
    echo "4. View Printed Logs"
    echo "5. Logout"
    echo -e "${YELLOW}=========================${NC}"
}

user_menu() {
    echo -e "${GREEN}\n===== USER PANEL =====${NC}"
    echo "1. Submit Print Job"
    echo "2. Logout"
    echo -e "${YELLOW}=========================${NC}"
}

# ========= FUNCTIONALITY =========
submit_job() {
    read -p "Enter document name: " doc_name
    echo "Select priority:"
    echo "1. High"
    echo "2. Medium"
    echo "3. Low"
    read -p "Choice [1-3]: " priority_choice

    case $priority_choice in
        1) priority="High" ;;
        2) priority="Medium" ;;
        3) priority="Low" ;;
        *) echo -e "${RED}Invalid choice. Defaulting to Medium.${NC}"
           priority="Medium" ;;
    esac

COUNTER_FILE="job_counter.txt"

# Initialize counter file if not exists
if [ ! -f "$COUNTER_FILE" ]; then
    echo 1 > "$COUNTER_FILE"
fi

# Read and increment counter
job_id=$(cat "$COUNTER_FILE")
echo $((job_id + 1)) > "$COUNTER_FILE"

    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$job_id|$doc_name|$priority|PENDING|$timestamp|" >> "$QUEUE_FILE"
    echo -e "${GREEN}Print job submitted successfully! Job ID: $job_id${NC}"
}

view_queue() {
    echo -e "${YELLOW}\n----- Current Print Queue (Sorted) -----${NC}"
    if [ ! -s "$QUEUE_FILE" ]; then
        echo -e "${RED}No jobs in the queue.${NC}"
    else
        printf "%-12s %-20s %-10s %-10s %-20s\n" "Job ID" "Document" "Priority" "Status" "Submitted"
        sort -t'|' -k3,3 -k5,5 "$QUEUE_FILE" | while IFS="|" read -r id name pri stat time extra; do
            short_id="${id:0:8}"
            echo -e "$short_id\t$name\t$pri\t$stat\t$time"
        done
    fi
}

cancel_job() {
    read -p "Enter Job ID (first 8 chars): " short_id
    found_id=$(grep "^$short_id" "$QUEUE_FILE" | cut -d'|' -f1)
    if [ -n "$found_id" ]; then
        sed -i "/^$found_id|/d" "$QUEUE_FILE"
        echo -e "${RED}Job $short_id cancelled successfully.${NC}"
    else
        echo -e "${RED}Job ID not found.${NC}"
    fi
}

mark_printed() {
    read -p "Enter Job ID (first 8 chars): " short_id
    full_id=$(grep "^$short_id" "$QUEUE_FILE" | cut -d'|' -f1)
    job_line=$(grep "^$full_id|" "$QUEUE_FILE")

    if [ -n "$job_line" ]; then
        completion_time=$(date +"%Y-%m-%d %H:%M:%S")
        updated_line=$(echo "$job_line" | sed "s/|PENDING|/|PRINTED|/")
        updated_line="${updated_line}${completion_time}"
        echo "$updated_line" >> "$LOG_FILE"
        sed -i "/^$full_id|/d" "$QUEUE_FILE"
        echo -e "${GREEN}Job $short_id marked as printed.${NC}"
    else
        echo -e "${RED}Job not found or already printed.${NC}"
    fi
}

view_logs() {
    echo -e "${YELLOW}\n----- Printed Job Log -----${NC}"
    if [ ! -s "$LOG_FILE" ]; then
        echo -e "${RED}No jobs have been printed yet.${NC}"
    else
        printf "%-12s %-20s %-10s %-20s %-20s\n" "Job ID" "Document" "Priority" "Submitted" "Printed"
        while IFS="|" read -r id name pri stat submit_time print_time; do
            short_id="${id:0:8}"
            echo -e "$short_id\t$name\t$pri\t$submit_time\t$print_time"
        done < "$LOG_FILE"
    fi
}

# ========= MAIN LOOP =========
while true; do
    main_menu
    read -p "Select an option [1-3]: " main_choice

    case $main_choice in
        1)
            echo -e "${BLUE}Logged in as Admin${NC}"
            while true; do
                admin_menu
                read -p "Select an option [1-5]: " admin_choice
                case $admin_choice in
                    1) view_queue ;;
                    2) cancel_job ;;
                    3) mark_printed ;;
                    4) view_logs ;;
                    5) echo -e "${BLUE}Logging out...${NC}"; break ;;
                    *) echo -e "${RED}Invalid admin option.${NC}" ;;
                esac
            done
            ;;
        2)
            echo -e "${GREEN}Logged in as User${NC}"
            while true; do
                user_menu
                read -p "Select an option [1-2]: " user_choice
                case $user_choice in
                    1) submit_job ;;
                    2) echo -e "${GREEN}Logging out...${NC}"; break ;;
                    *) echo -e "${RED}Invalid user option.${NC}" ;;
                esac
            done
            ;;
        3) echo -e "${YELLOW}Exiting Printing Management System.${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
    esac
    echo
done
