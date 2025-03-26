#!/bin/bash
clear  # Clear the screen at the beginning

# Function to get the list of VMs and their statuses
get_vm_list() {
    vm_list=()
    vm_status=()
    while IFS= read -r line; do
        vm_list+=("$line")
        if vboxmanage list runningvms | grep -q "\"$line\""; then
            vm_status+=("RUNNING")
        else
            vm_status+=("STOPPED")
        fi
    done < <(vboxmanage list vms | awk -F\" '{print $2}')
}

# Function to display the VM selection menu with status
select_vm() {
    while true; do
        clear
        get_vm_list  # Get the latest VM list and statuses

        # Check if there are no VMs available
        if [ ${#vm_list[@]} -eq 0 ]; then
            echo "No virtual machines found on this system."
            exit 1
        fi

        echo "Select a VM by number (with status):"
        for i in "${!vm_list[@]}"; do
            echo "$((i+1))) ${vm_list[$i]} - ${vm_status[$i]}"
        done
        echo "$(($i+2))) Exit"

        read -p "Enter your choice: " choice

        # Handle exit option
        if [[ "$choice" -eq "$(($i+2))" ]]; then
            echo "Exiting script..."
            exit 0
        fi

        # Convert the choice to a VM name
        if [[ $choice -gt 0 && $choice -le ${#vm_list[@]} ]]; then
            vm_name="${vm_list[$((choice-1))]}"
        else
            echo "Invalid selection! Please try again."
            sleep 2
            continue
        fi

        manage_vm  # Go to VM management menu
    done
}

# Function to display action menu for a VM
manage_vm() {
    while true; do
        clear
        get_vm_list  # Refresh status before displaying the menu
        vm_index=$(printf '%s\n' "${vm_list[@]}" | grep -nx "$vm_name" | cut -d: -f1)
        vm_index=$((vm_index - 1))
        vm_current_status="${vm_status[$vm_index]}"

        echo "You chose VM: $vm_name ($vm_current_status)"
        echo ""
        echo "What do you want to do with it?"
        echo "1) Start the VM"
        echo "2) Shut down the VM (Soft)"
        echo "3) Force shutdown the VM (Power Off)"
        echo "4) Check VM status"
        echo "5) Go back to VM selection"
        read -p "Enter your choice: " action

        case "$action" in
        1)
            if [ "$vm_current_status" == "RUNNING" ]; then
                echo "The VM '$vm_name' is already running!"
            else
                vboxmanage startvm "$vm_name" --type headless
                echo "Starting VM '$vm_name'..."
            fi
            ;;
        2)
            if [ "$vm_current_status" == "RUNNING" ]; then
                vboxmanage controlvm "$vm_name" acpipowerbutton
                echo "Sending ACPI power button signal to VM '$vm_name'..."
            else
                echo "The VM '$vm_name' is already powered off!"
            fi
            ;;
        3)
            if [ "$vm_current_status" == "RUNNING" ]; then
                vboxmanage controlvm "$vm_name" poweroff
                echo "Force shutting down VM '$vm_name'..."
            else
                echo "The VM '$vm_name' is already powered off!"
            fi
            ;;
        4)
            vboxmanage showvminfo "$vm_name"
            ;;
        5)
            return  # Go back to VM selection
            ;;
        *)
            echo "Invalid option! Please choose 1, 2, 3, 4, or 5."
            ;;
        esac

        echo ""
        read -p "Press Enter to continue..."  # Pause before showing menu again
    done
}

# Start script execution
select_vm

