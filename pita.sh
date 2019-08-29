

#!/usr/bin/env sh




clean()
{
	case "$gitState" in 
    	false) 
           log "Exiting Normally"
           exit
           ;;
        stagged) 
           log "Unstagging all files. Moving back to HEAD"
           git reset HEAD
           rm output.txt
           log "Exiting"
           exit
           ;;
        committed) 
           log "Uncommiting. Moving back to HEAD"
           git reset HEAD~1
           rm output.txt
           log "Exiting"
           exit
           ;; 

    esac
   exit
}

log(){
	echo "[INFO]---> $1"
}
err(){
	echo "[ERROR] -> $1"
}

askpom(){

	log "Remember to Update Pom (S/N)?"
    read answer
    case "$answer" in 
    	s) 
			version=$(grep -e "appbat-webcrawler${name}</artifactId>" -n pom.xml > t && sed --quiet -n $(( $(grep --no-messages -o -e "[0-9]\+" t) + 1))p pom.xml > t && grep -o -e "[0-9\.]*" t)
			log "Actual version is: $version"
			rm t
           # version=$(findstr "<version>" pom.xml)
           # log "Actual version is:" 
           # log " $version" | sed -n 2p

           log "Is it correct (S/N)?"
           read answer
           case "$answer" in 
		    	s)  
		          ;;
		        n) log "Update pom and execute again"
		           exit
		           ;;
		        *) askpom

    esac

           ;;
        n) log "Update pom and execute again"
           exit
           ;;
        *) askpom

    esac

}

askstaged(){

	
    sleep 2
    status=$(git status)
    sleep 1
    if [[ $status != *"pom"* ]]
      then
		log "File pom.xml dosent differ from HEAD. Can´t stage"
		sleep 1
	fi
    
    if  [[ $status != *"/${names}SpiderProcess.java"* ]]
    	then
        log "File /${names}SpiderProcess.java dosent differ from HEAD. Can´t stage"
        sleep 1
    fi  
    
    log "Executing Status."
    echo "    "
    sleep 1
    git status
    sleep 1
	log "Are al the files needed stagged (S/N)?"
    read answer
     case "$answer" in 
    	s) 
           ;;
        n) log "Write command of file needed to be stagged. (file1 file2 file3 ...)." 
           read answer 
           git add $answer
           askstaged
           ;;
        *) askstaged

    esac

}

askcommit(){
	 log "Check commit message"
	 echo "         "
    sleep 2
    git log
    log "Are you stasified with the message (S/N)?"
    read answer 
    case "$answer" in 
    	s) 
           ;;
        n) log "Write new commit message." 
           read answer 
           git commit --amend -m $answer
           askcommit
           ;;
        *) askcommit
    esac
}

askpush(){

    log "Everything Done. Push to develop (S/N)?"
    read answer
     case "$answer" in 
    	s) # git -c http.sslVerify=false push
           ;;
        n) clean
           ;;
        *) askpush
    esac
    
}

mergeFunc(){

	log "Do you want to merge to master? (s/n)"
    read answer 
     case "$answer" in 
    	s) 
           master=$(git checkout master)
           log "Change branch to master"
           sleep 1
    	   # git merge develop  
           ;;
        n) log "Do you want to return to the state before running the script? (s/n)"
           read answer 
            case "$answer" in 
		    	s) clean
		           ;;
		        n) log "Exiting without returning to previous state."
				   rm output.txt
				   log "Finished"

		           ;;
		        *) askpush
            esac
            ;;
        *) askpush
    esac
}

gitFunc()
{

	trap  clean SIGINT

    askpom
	branch=$(git --git-dir ../.git branch | grep \*)
	if [[ $branch != *"develop"* ]]; then
		git checkout develop
    fi

    fileName="src/main/java/com/inditex/ecom/appbatwebcrawler${name}/process/strategy/${names}SpiderProcess.java"
    log "Stagging Pom.xml and /${names}SpiderProcess.java"
    sleep 2
    git add pom.xml
    git add $fileName
    
    sleep 2
    gitState=stagged

    askstaged
   
    log "Write commit sentence"
    read answer
    git commit -m answer
    girState=commited
    askcommit

    askpush

    #mergeFunc




}



declare condition
declare code
declare path 
declare run
declare gitState=false


case $1 in 
	PB) 
         log "Executing Pull&Bear"
	     code=2
	     name="pull"
	     names="Pull"
         ;;

    BK)  log "Executing Bershka"
         code=4
         name="bershka"
	     names="Bershka"
         ;;
    ST)  log "Executing Stradivarius"
         code=6
         name="stradivarius"
	     names="Stradivarius"
         ;;
	OY)  log "Executing Oysho"
         code=7
         name="oysho"
	     names="Oysho"
         ;;
	DT)  log "Executing Massimo Dutti"
         code=11
         name="dutti"
	     names="Dutti"
         ;;
	ZH)  log "Executing ZaraHome"
         code=14
         name="zarahome"
	     names="Zhome" 
         ;;
	UT)  log "Executing Uterque"
         code=18
         name="uterque"
	     names="Uterque"
         ;;
    -help) log "
Pull&Bear->PB
Bershka->BK
Stradivarius->ST
Oysho->OY
Dutti->DT
ZaraHome->ZH
Uterque->UT"
          exit
          ;;

     *) log "Option Not Found (-help) to see Stores"
        exit
        ;;
esac





path="target/ECRAWL$1"
run="./$path/bin/run.cmd"
touch output.txt
log "Running Maven Clean Install"
mvn clean install >> output.txt
condition=$(findstr "BUILD" output.txt)
sleep 1



case "$condition" in
    *SUCCESSFUL*) 
       log "BUILD SUCCESSFUL"
 	   log "UNZIPPING..."
	   mkdir $path
	   zip=$(unzip $path -d $path)
	   log "RUNNING SPIDER..."
	   sleep 1
       $run -c $code
       read p
       sleep 2
       log "Do you Want to push to the repository (S/N)?"
       read answer
       case "$answer" in 
       	s)  gitFunc name names
            ;;
        *)  log "Not Pushing. Exiting.."
            ;;
       esac
     ;;

    *FAILURE* ) err "BUILD FAILURE";;

    *) err "Error: Executing mvn clean install";;	
esac

rm output.txt
log "Finished"

