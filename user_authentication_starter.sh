#!/bin/bash
## to be updated to match your settings
PROJECT_HOME="."
credentials_file="$PROJECT_HOME/credentials.txt"

# Function to prompt for credentials
get_credentials() {
    read -p 'Username: ' user
    read -rs -p 'Password: ' pass
    echo
}

generate_salt() {
    openssl rand -hex 8
    return 0
}

## function for hashing
hash_password() {
    # arg1 is the password
    # arg2 is the salt
    password=$1
    salt=$2
    # we are using the sha256 hash for this.
    echo -n "${password}${salt}" | sha256sum | awk '{print $1}'
    return 0
}

check_existing_username(){
    username=$1
    ## verify if a username is already included in the credentials file
    if grep -q "$username:" "$credentials_file"; then
        echo "$username already exists."
        return 1

    fi
    return 0
}

## function to add new credentials to the file
register_credentials() {
    # arg1 is the username
    # arg2 is the password
    # arg3 is the fullname of the user
    # arg4 (optional) is the role. Defaults to "normal"
    # echo "===== User Registration ====="
    username="$1"
    password="$2"
    fullname="$3"
    role="${4:-normal}"
    

    ## call the function to check if the username exists
    check_existing_username $username
    #TODO: if it exists, safely fails from the function.
    # if [$? -ne 0]; then
    #     return 1
    # fi
    ## retrieve the role. Defaults to "normal" if the 4th argument is not passed
    if [ -z "$role" ]; then
        role="normal"

    fi
    ## check if the role is valid. Should be either normal, salesperson, or admin

    ## first generate a salt
    salt=`generate_salt`
    ## then hash the password with the salt
    hashed_pwd=`hash_password $password $salt`
    ## append the line in the specified format to the credentials file (see below)
    ## username:hash:salt:fullname:role:is_logged_in
    echo "$username:$hashed_pwd:$salt:$fullname:$role:0"  >> $credentials_file
    # echo "$username registered successfully"
    return 0
}

# Function to verify credentials
verify_credentials() {
    ## arg1 is username
    ## arg2 is password
    username=$1
    password=$2
    ## retrieve the stored hash, and the salt from the credentials file

    stored_data=$(grep "^$username:" "$credentials_file")
    stored_hash=$(echo "$stored_data" | cut -d ":" -f 2)
    stored_salt=$(echo "$stored_data" | cut -d ":" -f 3)
    # if there is no line, then return 1 and output "Invalid username"
    if [ -z "$stored_hashed_pwd" ]; then
        echo "Invalid username or password"
        return 1
    fi
    input_hashed_pwd=$(hash_password "$password" "$salt")
    # comparering the stored hashed pwd
    if [ "$stored_hashed_pwd" = "$input_hashed_pwd" ]; then
        return 0
    else 
        return 1
    fi
    
    # stored_hash=$(grep "$stored_data" | cut -d ":" -f 2)
    # stored_salt=$(echo "$stored_data" | cut -d ":" -f 3)
    ## Check if the credentials file exists, if not, create it.
    if [ ! -e "$credentials_file" ]; then
        touch "$credentilas_file"
    fi
}

# Login function
login() {
    echo "===== Login ====="
    read -p "Enter username: " username
    read -s -p "Enter password: " password

    verify_credentials $username $password
    echo "Welcome $username you have successfully logged in as normal."
    # exit 0
}


# Register function        
register() {
    echo =====Registration =====
    echo "Select option:"
    echo "1. Self_registration"
    echo "2. Admin_registration"
    read -p "Enter your registration choice:" registration_option
    echo $registration_option

case $registration_option in
    1)
        self_registration
        ;;
    2)
        admin_registration
        ;;
    *)
        echo "Invalid choice. Please enter a valid option!"
        ;;
    esac 
}
self_registration(){
    echo "====== Self Registration==="
    read -p "Enter username: " username
    read -s -p "Enter password: " password
    echo
    read -p "Enter Full Name: " fullname
    role="normal"
    register_credentials "$username" "$password" "$fullname" "$role"
}


admin_registration(){
    echo "===== Admin Registration ====="
    read -p "Enter username: " username
    read -s -p "Enter password: " password
    echo
    # read -s -p "Confirm password: " password
    # echo
    read -p "Enter full name: " fullname

    while true; do
        read -p "Enter your role (admin/normal/salesperson): " role
        if [[ "$role" == "admin" || "$role" == "normal" || "$role" == "salesperson" ]]; then
            break
        else
            echo "Invalid role. Please enter a valid role."
        fi
    done
register_credentials $username $password $fullname $role
} 


logout() {

    #TODO: check that the .logged_in file is not empty
    # if the file exists and is not empty, read its content to retrieve the username
    # of the currently logged in user

    # then delete the existing .logged_in file and update the credentials file by changing the last field to 0
    exit 0
}
welcome_menu() {
    echo "Welcome to the authentication system."
    echo "Select option:"
    echo "1. Login"
    echo "2. Register"
    echo "3. Logout"
    echo "4. Close the program"
    read -p "Enter your choice:" option
    echo $option

    
case $option in
    1)
        login
        ;;
    2)
        register
        ;;
    3)
        logout
        ;;
    4)
        echo "Closing the program. Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice. Please enter a valid option!"
        ;;
    esac
}

## Create the menu for the application
# at the start, we need an option to login, self-register (role defaults to normal)
# and exit the application.

# After the user is logged in, display a menu for logging out.
# if the user is also an admin, add an option to create an account using the 
# provided functions.

# Main script execution starts here
welcome_menu


#### BONUS
#1. Implement a function to delete an account from the file