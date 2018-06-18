set-psdebug -strict

. core.ps1
#. subversion.ps1

function delete-customs {
	param($cust=$((get-buildsettings).settings.customer))
	log ("Removing Customs matching: {0}" -f $customer_regex)
	(ls -r )|
		?{$_ -is [IO.DirectoryInfo]}|
		?{$_.Name -imatch $customer_regex}|
		?{$cust -ne $matches["customer"]}|
		?{test-path $_.FullName}|
		%{
			log ("removing {0}" -f $_.FullName);
			rm -r -fo $_.FullName
		}
}

function update-webconfigthemes {
	param($cust=$((get-buildsettings).settings.customer))
	$cust=$cust.ToUpper()
	log ("Setting Web.Config Themes to '{0}'" -f $cust)
	pushd sites
	& {
		trap{popd;throw $_}
		(ls -r -filter web.config)|?{-not $_.FullName.Contains("employee")}|%{
			$wc = [xml](gc $_.FullName)
			$sw = $wc.configuration."system.web"
			if($sw -and $sw.pages){
				$sw.pages|
					?{$_.theme}|
					?{$_.theme -ne $cust}|
					%{$_.theme = $cust}
			}
			$wc.Save($_.FullName)
		}
	}
	popd
}

function prepare-features {
	param(
		$config=$(get-buildsettings),
		$working=$(get-workingdirectory $config)
	)
	$cust=$config.settings.customer
	delete-customs $cust
	update-webconfigthemes $cust

	log ("`nPrepare-Features:" -f $cust)

	$customer=get-customerfeatures $cust
	$available=get-availablefeatures $customer.features.version
	# remove #defines already set
	$available.features.feature|?{$_}|%{
		$af=$_.name
		$define=$af.ToUpper()
		log ("Processing Feature: {0}" -f $define)
		$_.project|?{$_}|%{
			(ls $working -r -i $_.name)|?{$_}|%{
				$proj = [xml](gc $_)
				$proj.Project.PropertyGroup|
					?{$_.DefineConstants}|
					?{$_.DefineConstants -match $define}|
					%{$_.DefineConstants = $_.DefineConstants.Replace($define,"").Replace(";;",";")}
				$proj.Save($_.FullName)
			}
		}

		if(-not($customer.features.feature -match $af)){
			log "Removing unused files/folders"
			$_.artifact|?{$_}|%{
				if(test-path $_){
					log ("Remove: {0}" -f $_)
					rm -r -fo $_
				}
			}
		}
	}


	if($customer -and $customer.features -and $customer.features.feature){
		log "Adding customer specific features back into the compile"
		$customer.features.feature|%{
			$cf=$_
			$define=$cf.ToUpper()
			log ("Processing Feature: {0}" -f $define)
			# set project #define's
			$available.features.feature|?{$cf -eq $_.name}|%{
				log ("  Customer Feature: {0}" -f $cf)
				$_.project|?{$_}|%{
					log ("   Project {0} in {1}" -f $_.name, $working)
					(ls -r -inc $_.name $working)|?{$_}|%{
						$proj = [xml](gc $_)
						log ("    Updating {0}" -f $_.fullname)
						$proj.Project.PropertyGroup|
							?{$_.DefineConstants}|
							?{$_.DefineConstants -notmatch $define}|
							%{
								log ("      Adding #define {0}" -f $define)
								$_.DefineConstants=("{0};{1}" -f $_.DefineConstants,$define)
							}
						$proj.Save($_.FullName)
					}
				}
			}
		}
	}else{warn "Customer features not found"}
}
