function setup-tf {
	for i in aws azure gcp ibm   ; do 
		if [[ -d "$i" ]] then
			ln -vnsf $HOME/Documents/rp-overrides/terraform/$i/_override.tf $i/ 
		fi
	done

}
