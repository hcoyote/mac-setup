
function check-pr {

repo=$1
pr=$2

prdir="${3:-$HOME/Documents/github/prs}"


project=$(basename "${repo}")
owner=$(dirname "${repo}")

prdirname=$(echo "pr-${pr}/${repo}" | tr / -)


if [[ -z "$repo" ]] ; then
	echo "supply a repo name <owner>/<repo>"
	exit 1
fi

if [[ -z "$pr" ]]; then
	echo "supply a pr number"
	exit 1

fi

if ! command -v gh &> /dev/null
then
    echo "gh could not be found - install it or modify PATH env"
    exit
fi


if [[ ! -d "${prdir}" ]] ; then
	echo "creating pr directory ${prdir}"
	mkdir -vp "${prdir}"
fi



if [[ ! -d "${prdir}/${prdirname}" ]] ; then
	echo "creating ${prdirname}"
	mkdir -p "${prdir}/${prdirname}"
fi

cd "${prdir}/${prdirname}" && echo "changing to ${prdir}/${prdirname}"

if [[ ! -d ".git" ]] ; then 
	echo "Cloning repo and checking out PR $pr"
	gh repo clone "${repo}" . && \
	gh pr checkout "$pr"
fi 

gh pr view --web

}
