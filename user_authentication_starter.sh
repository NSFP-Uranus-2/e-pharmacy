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
    if grep -q "^$username:" "$credentials_file"; then
        echo "$username already exists."
        return 0
    fi
        return 1
}


## function to add new credentials to the file
register_credentials() {
    # arg1 is the username
    # arg2 is the password
    # arg3 is the fullname of the user
    # arg4 (optional) is the role. Defaults to "normal"
    username="$1"
    password="$2"
    fullname="$3"
    role=${4:-"normal"}

    ## call the function to check if the username exists
    check_existing_username $username
    #if it exists, safely fails from the function.
    if [ $? -eq 0 ]; then
        echo "Registration failed: username exists"
        return 1
    fi

    ## first generate a salt
    salt=`generate_salt`
    ## then hash the password with the salt
    # hashed_pwd=`hash_password $password $salt`
    hashed_pwd=$(hash_password "$password" "$salt")
    ## append the line in the specified format to the credentials file (see below)
    ## username:hash:salt:fullname:role:is_logged_in
    echo "$username:$hashed_pwd:$salt:$fullname:$role:1"  >> $credentials_file
    echo "$username registered successfully"
    # return 0
}


# Function to verify credentials
verify_credentials() {
    ## arg1 is username
    ## arg2 is password
    username=$1
    password=$2

    ## retrieve the stored hash, and the salt from the credentials file
    stored_data=$(grep "^$username:" "$credentials_file")
    if [ -z "$stored_data" ]; then
        echo "Invalid username "
        return 1
    fi
    stored_hash=$(echo "$stored_data" | cut -d ":" -f 2)
    stored_salt=$(echo "$stored_data" | cut -d ":" -f 3)
    # if there is no line, then return 1 and output "Invalid username"
    # compute the hash based on the provdied password
    input_hashed_pwd=$(hash_password "$password" "$stored_salt")
    # comparering the stored hashed pwd
    if [ "$input_hashed_pwd" = "$stored_hashed_pwd" ]; then
        echo "$username" > "$PROJECT_HOME/.logged_in"
    fi
}

# Login function
login() {
    echo "===== Login ====="
    read -p "Enter username: " username
    stored_data=.$(grep "^$username:" "$credentials_file")

    if [ -z "$stored_data" ]; then
        echo ""Invalid username
        return 1
    
    fi


    read -s -p "Enter password: " password
    echo

    stored_hash=$(echo "$stored_data" | cut -d ":" -f 2)
    stored_salt=$(echo "$stored_data" | cut -d ":" -f 3)
    input_hashed_pwd=$(hash_password "$password" "$stored_salt")

    if [ "$input_hashed_pwd" = "$stored_hash" ]; then
        echo "$username" > "$PROJECT_HOME/.logged_in"
        echo "Welcome $username, you have successfully logged in as normal..."
    else
        echo "Invalid password"
    fi
    return 0

    verify_credentials "$username" "$password"
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

# Admin_credentials
admin_username="Admin"
admin_password="Admin@1234"

admin_registration(){
    echo "===== Admin Registration ====="

    read -p "Admin username:" input_username
    read -s -p "Enter admin password:" input_password
    echo

    if [[ "$input_username" == "$admin_username" && "$input_password" == "$admin_password" ]]; then
        echo "Admin successfully registered."

# admin_registration
        while true; do
            read -p "Do you want to register another user? (yes/no): " continue_register
            if [[ "$continue_register" == "yes" ]]; then 
                read -p "Enter username: " username
                read -s -p "Enter password: " password
                echo
                read -p "Enter full name: " fullname

                while true; do
                    read -p "Enter user role (admin/normal/salesperson): " role
                    if [[ "$role" == "admin" || "$role" == "normal" || "$role" == "salesperson" ]]; then
                        break
                    else 
                        echo "Invalid role. Please enter a valid role"
                    fi
                done
                register_credentials "$username" "$password" "$fullname" "$role"
            else
                echo "Thank you for your time"
                break
            fi
        done
    else
        echo "Invalid admin credentials. Only Admin can access"    
fi
}

# Logout function
exit() {
    echo "==== Exit ====="
    echo "1. Logout"
    echo "2. Delete Account"
    read -p "Enter your choice:" exit_option
    echo "$exit_option"

case $exit_option in
    1)
        logout
        ;;
    2)  
        delete_account
        ;;
    *)
        echo "Invalid choice. Please enter valid option"
    esac    
}
    logout (){
    #TODO: check that the .logged_in file is not empty
    if [ -s "$PROJECT_HOME/.logged_in" ]; then
    # if the file exists and is not empty, read its content to retrieve the username of the currently logged in user
    username=$(cat "$PROJECT_HOME/.logged_in")
    
    # delete the existing logged_in_file
    rm "$PROJECT_HOME/.logged_in"


    # then delete the existing .logged_in file and update the credentials file by changing the last field to 0
    sed -i "s/^$username:.*$/&:0/" "$credentials_file"

    echo "Logged out successfully"
else
    echo "No user is currently logged in."
fi
    # exit 0
}

# #### BONUS
# function to delete an account from the file
delete_account (){
    echo "===== Delete Account ====="
    read -p "Enter the username of the account you want to delete: " delete_username

    # checking if the file exist in the credentials
    if grep -q "^$delete_username:" "$credentials_file"; then
        # checking the new credentials file
        grep -v "^$delete_username:" "$credentials_file" > "$credentilas_file.tmp"
        mv "$credentials_file.tmp" "$credentilas_file"
        echo "Account $delete_username" has been deleted.
    else 
        echo "Account $delete_username not found."
    fi

    read -p "Press Enter to continue.."

}

# Welcome Menu function
welcome_menu() {
    echo "Welcome to the authentication system."
    echo "Select option:"
    echo "1. Login"
    echo "2. Register"
    echo "3. Exit"
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
        exit
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
welcome_menu
