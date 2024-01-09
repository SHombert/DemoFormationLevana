public without sharing class AccountHandler {
  public static void CheckDuplicates(List<Account> lAccount){
    set<String> sNameShort=new set<String>();
    set<String> sNameLong=new set<String>();
    Map<String, parameter__c> params = parameter__c.getAll();
    Integer iMinimumMatchingAccount = Integer.valueof(params.get('MinimumMatchingAccount').value__c);
    Integer iLimit;
   
   // TODO : iLimit = math.min(iLimit, account.name.length())
   
    RecordType personRecordType = [
      select Id 
      from RecordType
      where
        (sObjectType = 'Account') and
        (isActive = true) and
        (DeveloperName = 'PersonAccount')
      limit 1
    ];
    
      for(Account oAccount:lAccount){
          /*ALS 2018 21 02 *************************/
          //if(oAccount.RecordTypeId != personRecordType.Id){
          if(oAccount.isPersonAccount == false){
              /*************************ALS 2018 21 02*/
              iLimit = Math.min(iMinimumMatchingAccount, oAccount.Name.length());
	      	if(oAccount.Name.length() > iLimit)
	        	sNameLong.add(oAccount.Name.substring(0,iLimit) + '%');
	      	else sNameShort.add(oAccount.Name);
    	}
    }
    
    // recherche dans les comptes en base
    List<Account> lAccountPotentialDuplicatesLong = [select Name,Id from Account where Name LIKE :sNameLong AND Name != null AND RecordTypeId != :personRecordType.Id];
    List<Account> lAccountPotentialDuplicatesShort = [select Name,Id from Account where Name = :sNameShort AND Name != null AND RecordTypeId != :personRecordType.Id];
    
    // recherche dans la liste qui déclenche le trigger
    for(Account oAccount:lAccount){
    	/*ALS 2018 21 02 *************************/
        //if(oAccount.RecordTypeId != personRecordType.Id){
        if(oAccount.isPersonAccount == false){
            /*************************ALS 2018 21 02*/
    		iLimit = Math.min(iMinimumMatchingAccount, oAccount.Name.length());
			if(oAccount.Name.length() > iLimit)
				lAccountPotentialDuplicatesLong.add(oAccount);
			else lAccountPotentialDuplicatesShort.add(oAccount);
    	}
    }
    
    map<String,Integer> mlAccountLong = new map<String,Integer>();
    map<String,Integer> mlAccountShort = new map<String,Integer>();
    map <string, List<Account>> mlAccountList = new map <string, List<Account>>();
    List<Account> lAcc;    

    for(Account oAccount:lAccountPotentialDuplicatesLong){
		iLimit = Math.min(iMinimumMatchingAccount, oAccount.Name.length());
    	
    	if(mlAccountLong.get(oAccount.Name.substring(0,iLimit)) == null){
        	mlAccountLong.put(oAccount.Name.substring(0,iLimit),1);
        
	    	lAcc = new List<Account>();
	    	lAcc.add(oAccount);
	    
        	mlAccountList.put(oAccount.Name.substring(0,iLimit), lAcc);
      	}else{
      		mlAccountLong.put(oAccount.Name.substring(0,iLimit),mlAccountLong.get(oAccount.Name.substring(0,iLimit)) + 1);
      		mlAccountList.get(oAccount.Name.substring(0,iLimit)).add(oAccount);
      	}
    }
    
    for(Account oAccount:lAccountPotentialDuplicatesShort){
    	iLimit = Math.min(iMinimumMatchingAccount, oAccount.Name.length());
    	
  		if(mlAccountShort.get(oAccount.Name) == null){
    		mlAccountShort.put(oAccount.Name,1);
    
    		lAcc = new List<Account>();
    		lAcc.add(oAccount);
    
    		mlAccountList.put(oAccount.Name.substring(0,iLimit), lAcc);
    
  		}else{
  			mlAccountShort.put(oAccount.Name,mlAccountShort.get(oAccount.Name) + 1);
  			mlAccountList.get(oAccount.Name).add(oAccount);
  		}
    }
    
    for(Account oAccount:lAccount){
       	/*ALS 2018 21 02 *************************/
          //if(oAccount.RecordTypeId != personRecordType.Id){
          if(oAccount.isPersonAccount == false){
              /*************************ALS 2018 21 02*/
    		iLimit = Math.min(iMinimumMatchingAccount, oAccount.Name.length());
       		
	      	if(sNameShort.contains(oAccount.Name)){
	        	oAccount.Potential_duplicates_values__c = mlAccountShort.get(oAccount.Name);
	        
	        	/*for(Account oAccount2 : mlAccountList.get(oAccount.Name)){
	        		oAccount.Description += '\n'+oAccount2.Id + ' - ' + oAccount2.Name;
	        	}*/
	        
	      	}else{
	      		if(sNameLong.contains(oAccount.Name.substring(0,iLimit)+'%')){
	        		oAccount.Potential_duplicates_values__c = mlAccountLong.get(oAccount.Name.substring(0,iLimit));
	        		
	        	    /*for(Account oAccount2 : mlAccountList.get(oAccount.Name.substring(0,iLimit))){
			        	oAccount.Description += '\n'+oAccount2.Id + ' - ' + oAccount2.Name;
			        }*/	        
	      		}
	      	}
       	}
	}
  }
    public static void accountWithRelatedPreventDeletion(List <Account> triggerOld)
    {
        
        Set <String> accIdsSet = new Set <String> ();
        for (Account acc : triggerOld){
            accIdsSet.add(acc.Id);
        }
        
        Map <Id,Account> mapAcc = new Map <Id,Account> ([SELECT Id,
                                                         (SELECT Id FROM Contacts), 
                                                         (SELECT Id FROM Opportunities) 
                                                         FROM Account
                                                        WHERE Id IN :accIdsSet]);
        
        Map <Account, Integer> mapDelete = new Map <Account, Integer>();
        List <Account> accDelete = new List <Account>();
        List <Account> accToBlock = new List <Account>();
        
        for(Account acc : triggerOld){
            Integer nbSum = 0;
            
            if(mapAcc.get(acc.Id) != null){
                nbSum += mapAcc.get(acc.Id).Contacts.size();
                nbSum += mapAcc.get(acc.Id).Opportunities.size();
            }
            
            mapDelete.put(acc , nbSum);

        }
        for (Account acc : mapDelete.keyset()){
            if (mapDelete.get(acc) > 0){
                acc.adderror(label.ErrorMessage_AccountWithRelated);
            }
        }
        
    }
}