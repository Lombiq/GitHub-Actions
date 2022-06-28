#!/bin/bash

###################################################################################################
# add-package                                                                                     #
###################################################################################################
# Adds a NuGet package to projects in the solution or the project file. Use it in the git         #
# repository's root directory.                                                                    #
#                                                                                                 #
# Use shellcheck (https://github.com/koalaman/shellcheck) for linting and shell-format            #
# (https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format) for styling.    #
###################################################################################################

function program() {

    package_name="$1"

    function err() {
        echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
    }

    function panic() {
        error_code="$1"
        shift

        for line in "$@"; do
            err "$line"
        done

        exit "$error_code"
    }

    function alter-solution() {
        solution_file="$1"
        [ -f "$solution_file" ] || panic 1 "Couldn't find the solution '$solution_file' in '$PWD'."

        for project_path in $(dotnet sln "$solution_file" list | sed '1,2 D'); do
            directory="$(dirname "$solution_file")/$(dirname "$project_path")"

            pushd "$directory" || panic 2 "Couldn't open the project directory '$directory'."
            alter-project "$(basename "$project_path")"
            popd || panic 3 "Couldn't return to the original directory."
        done
    }

    function alter-project() {
        project_file="$1"
        [ -f "$project_file" ] || panic 4 "Couldn't find the project '$project_file' in '$PWD'."

        dotnet add "$project_file" package "$package_name"
    }

    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo
        basename "$0"
        echo
        echo "USAGE"
        echo -e "\tbash $(basename "$0") package_name [solution.sln]\n"
        echo "package_name - The name of a NuGet package. The same you'd pass to 'dotnet add package'."
        echo "solution.sln - Optional argument to provide the path to the solution file. If none are"
        echo "               provided then the script looks for .sln or if none found then for .??proj"
        echo "               (i.e. csproj, fsproj, vbproj) in the current working directory."
    else
        # The NuGetBuild property need to set so we don't get errors due to wrong references that are targeted at
        # non-NuGet builds.
        printf "<Project>\n  <PropertyGroup>\n    <NuGetBuild>true</NuGetBuild>\n  </PropertyGroup>\n</Project>" > Directory.Build.props

        if [ -f "$2" ]; then
            alter-solution "$2"
        elif solutions=(./*.sln) && ((${#solutions[@]})) && [ -f "${solutions[0]}" ]; then
            for solution in "${solutions[@]}"; do
                alter-solution "$solution"
            done
        else
            for project in ./*.??proj; do
                alter-project "$project"
            done
        fi
    fi

}

program "$@"
