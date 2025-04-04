#!/bin/bash

# pushd "/opt/clipboard/" || exit

if [ "$(whoami)" != "podman" ]; then
    echo "run this script as 'podman' user, via 'sudo -u podman'."
    return 1
fi

# Define the containers paths
container_images_path="./container_images"
image_tar=""
selected_version=""
operation_output_string=""
semver_regex="(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"

# Function to print containers list
function print_containers_list() {
    echo -e "*** PODMAN CONTAINERS ***"
    podman container list
    echo
}

# Function to clear screen and print containers list
function refresh_screen() {
    clear
    print_containers_list
    echo -e "$operation_output_string"
}

function select_container_image() {
    local base_container_file_name=$1;
    # Find all tar files for the container, store in an associative array
    images_tar=()
    while IFS=  read -r -d $'\0'; do
        local filename=$(basename "$REPLY")
        local filenameWithoutTar=$(basename "$REPLY" .tar)
        # use regex to sort out the selected_version string from the files
        local version=$(echo "$filenameWithoutTar" | perl -nle"print $& if m{$semver_regex}")
        # local selected_version=$(echo "$filename" | awk 'match($0, /[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?/) {print substr($0, RSTART, RLENGTH)}')

        # Get the modification time in seconds since the Unix epoch
        local mod_time=$(stat -c %Y "$REPLY")

        # Concatenate the mod_time, selected_version, and filename together for sorting
        images_tar+=("$mod_time|$version|$REPLY")
    done < <(find "${container_images_path}/" -maxdepth 1 -type f -name "$base_container_file_name*.tar" -print0)

    # Sort the array in reverse, so the newest files are first
    IFS=$'\n' images_tar=($(sort -r <<<"${images_tar[*]}")); unset IFS

    versions=()
    for img in "${images_tar[@]}"; do
        # Extract the mod_time and selected_version from the concatenated string
        local mod_time="$(cut -d'|' -f1 <<<"$img")"
        local version="$(cut -d'|' -f2 <<<"$img")"
        local mod_time_formatted=$(date -d @"$mod_time" "+%d-%m-%Y %T")

        # Add the mod_time and selected_version to the versions array
        versions+=("$(printf '%-20s %s' "$version" "$mod_time_formatted")")
    done

    # add "Back" option to the versions
    versions+=("Back to main menu")

    echo -e "$(printf '   %-20s %s' "Version" "Date")"

    select selected_version in "${versions[@]}"; do
        if [ -n "$selected_version" ]; then
            # if "Back to main menu" option is selected, clear variables and break
            if [ "$selected_version" == "Back to main menu" ]; then
                image_tar=""
                selected_version=""
                echo "Returning to main menu..."
                operation_output_string=""
                return 2
            else
                for img in "${images_tar[@]}"; do
                    img_version="$(cut -d'|' -f2 <<<"$img")"
                    selected_version="$(cut -d' ' -f1 <<<"$selected_version")"
                    if [[ "$selected_version" == "$img_version" ]]; then
                        selected_version=$img_version
                        image_tar="$(cut -d'|' -f3 <<<"$img")"
                        break
                    fi
                done
            fi
            break
        else
            echo "Invalid selection. Please select a number from the list."
            image_tar=""
            selected_version=""
        fi
    done

    if [ -z "$image_tar" ]; then
        operation_output_string="No tar file found for container '$image_base_path' in directory '$container_images_path'"
        return 1
    fi

    echo "Chosen Version: $selected_version, Image Path: $image_tar"
    return 0
}

function update_docker_compose_version() {
    local container=$1
    local compose_file_path=$2
    local new_version=$3

    # perl command to replace the version
    perl -pi -e "s{image: $container:$semver_regex}{image: $container:$new_version}" "$compose_file_path"
    cat "$compose_file_path"
}

function import_container() {
    # Import image to podman
    echo "Importing image from tar: $image_tar"
    podman load -i "$image_tar"
}

function fully_restart_container() {
    container=$1
    compose_file_path=$2

    # Stop and remove running container
    echo "Stopping and removing the container: $container"
    podman stop "$container"
    podman rm "$container"

    # Run docker-compose file
    echo "Starting corresponding compose setup for container: $container"
    podman-compose -f "$compose_file_path" up -d
}

function restart_container() {
    container=$1
    echo "Stopping the container: $container"
    podman stop "$container"
    echo "Starting the container: $container"
    podman start "$container"

    operation_output_string="container restarted: $container"
}

function start_all() {
    echo "Starting compose setup!"
    podman-compose up -d
}

function change_container_version() {
    local nice_name=$1
    local container=$2
    local image_base_path=$3
    local compose_file_path=$4

    echo -e "Changing version of container: $nice_name"

    select_container_image "$image_base_path"
    local return_code=$?

    if [ "$return_code" -ne 0 ]; then
        return 1
    fi

    import_container

    # retag new version to :active
    #podman tag "${container}:${selected_version}" "${container}:active"

    # Ensure the image has the auto-update label
    #podman image set-label "$container_name:active" io.containers.autoupdate=registry

    # Restart container with the new image
    #podman auto-update

    update_docker_compose_version "$image_base_path" "$compose_file_path" "$selected_version"

    fully_restart_container "$container" "$compose_file_path"

    # update systemd unit with new container ID from deleting and recreating the container
    ./script_modules/generate_systemd_service.sh "$container"

    operation_output_string="Finished changing version of container: $nice_name \n\n"
}

function display_menu() {
    echo "Choose an option: "

    local options=("Select API version" "Select Client version" "Restart API container" "Restart Client container" "Startup All" "Quit")

    select opt in "${options[@]}"
    do
        case $opt in
            "Select API version")
                refresh_screen
                local nice_name="Clipboard API"
                local container="clipboard-api"
                local image_base_path="clipboard-api"
                local compose_file_path="./docker-compose.yaml"
                change_container_version "$nice_name" "$container" "$image_base_path" "$compose_file_path"
                return 0
                ;;
            "Select Client version")
                refresh_screen
                local nice_name="Clipboard Client"
                local container="clipboard-client"
                local image_base_path="clipboard-client"
                local compose_file_path="./docker-compose.yaml"
                change_container_version "$nice_name" "$container" "$image_base_path" "$compose_file_path"
                return 1
                ;;
            "Restart API container")
                refresh_screen
                local container="clipboard-api"
                restart_container $container
                return 2
                ;;
            "Restart Client container")
                refresh_screen
                local container="clipboard-client"
                restart_container $container
                return 3
                ;;
            "Startup All")
                refresh_screen
                start_all
                return 4
                ;;
            "Quit")
                echo "Quitting.."
                return 5
                ;;
        esac

    done
}

# Catch the EXIT signal
trap cleanup EXIT

cleanup() {
    # This will execute when the script exits
    printf "\033[?1049l"
}

# Enable alternate screen
printf "\033[?1049h"

# Start main loop
while :
do
    refresh_screen  # Refresh screen after entering each option
    display_menu
    result=$?
    if [ $result -eq 5 ]; then
        break
    fi
done
