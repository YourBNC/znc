#!/bin/bash -x

echo "Generating docs with doxygen..."

doxygen

mkdir -p ~/.ssh
chmod 0600 ~/znc-docs-key
cat <<EOF >> ~/.ssh/config
Host znc-docs
HostName github.com
User git
IdentityFile ~/znc-docs-key
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
EOF

cd "$HOME"
git config --global user.email "travis-ci@znc.in"
git config --global user.name "znc-travis"
git clone --depth=1 --branch=gh-pages znc-docs:znc/docs.git gh-pages || exit 1

cd "$TRAVIS_BUILD_DIR/doc/html/"
mv ~/gh-pages/.git ./
echo docs.znc.in > CNAME
git add -A

rm -f ~/docs_need_commit
git status
git status | perl -ne '/modified:\s+(.*)/ and print "$1\n"' | while read x; do
	echo Checking for useful changes: $x
	git diff --cached $x |
		perl -ne '/^[-+]/ and !/^([-+])\1\1 / and !/^[-+]Generated.*ZNC.*doxygen/ and exit 1' &&
		git reset -q $x ||
		{ echo Useful change detected; touch ~/docs_need_commit; }
done

if [[ ! -f ~/docs_need_commit ]]; then
	echo "Docs at gh-pages are up to date."
	exit
fi

git commit -F- <<EOF
Latest docs on successful travis build $TRAVIS_BUILD_NUMBER

ZNC commit $TRAVIS_COMMIT
EOF
git push origin gh-pages

echo "Published docs to gh-pages."

