#!/bin/bash

orig_repo="$HOME/devel/herecura"

(
    cd "$orig_repo"
    git pull
)

branches=$(cd "$orig_repo"; find -mindepth 1 -maxdepth 1 -type d | grep -v '^.\/\.' | sed -e 's/\.\///')

#echo "${branches[@]}"

for branch in ${branches[@]}; do
    packages=$(cd "$orig_repo/$branch"; find -mindepth 1 -maxdepth 1 -type d | grep -v '^.\/\.' | sed -e 's/\.\///')

    if [[ "$branch" == "stable" ]] || [[ "$branch" == "testing" ]]; then
        targetbranch="herecura"
    elif [[ "$branch" == "pre-community" ]]; then
        targetbranch="blackeagle-pre-community"
    else
        targetbranch="master"
    fi

    #echo "${packages[@]}"

    for package in ${packages[@]}; do
        # clone into package specific repo
        git clone --no-hardlinks "$orig_repo" "$package-clone"
        (
            cd "$package-clone"
            # filter out the package
            git filter-branch --subdirectory-filter "$branch/$package" HEAD -- --all
            # to reduce the size of .git foler we will rebuild history via patches
            git format-patch origin
        )
        mkdir "$package"
        (
            cd "$package"
            source ../"$package-clone"/PKGBUILD
            # create a fresh repo per package
            git init
            # simple readme
cat <<EOT > README.md
$pkgname
========================================

url = ${url[@]}
EOT
            # add herecura .gitignore
            cp "$orig_repo"/.gitignore ./
            echo "*.pkg.tar.?z" >> .gitignore

            # apply the patches to rebuilt history
            for patch in $(find ../"$package-clone" -name "[0-9][0-9][0-9][0-9]*.patch" | sort -V); do
                git am "$patch"
                mksrcinfo
                git add -A
                git commit --amend --no-edit
            done

            # create a specific branch for the target package repo
            git branch -m "$targetbranch"

            # when archbuild is finished completely to work with split
            #hub create -d "herecura package $package" -h "http://repo.herecura.eu" herecura/$package
            #git push -u
        )
        # remove intermediate folder
        rm -rf "$package-clone"
    done
done
