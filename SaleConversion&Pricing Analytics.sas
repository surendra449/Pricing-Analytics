/* Process 1 */

libname Q '';

data TI;
 set Q.TI;
 if QUOTE_CONVERSION_STATUS eq 'CONVERTED' then Converted = 1; else Converted=0;
 if competitor eq "COMPETITOR DOESN'T EXIST" then competition=0; else competition=1;
 * srp = 'suggested retail price'; 
 discount1 =  TI_SRP_OFFER_PRICE_GC - NEGOTIATED_PRICE_GC;
 if SUGGESTED_CHANNEL_PRICE_GC>0 then discount2 = (SUGGESTED_CHANNEL_PRICE_GC - NEGOTIATED_PRICE_GC)/OTC; else discount2=0;
 if COMPETITOR_PRICE_GC>0 then discount3 = (COMPETITOR_PRICE_GC-NEGOTIATED_PRICE_GC)/OTC; else discount3=0;
run;
proc means;
 var discount1 discount2 SUGGESTED_CHANNEL_PRICE_GC TI_SRP_OFFER_PRICE_GC NEGOTIATED_PRICE_GC;
run;
proc means;
 var discount3;
run;

proc means;
 var COMPETITOR_PRICE_GC;
run;

proc contents;
run;

proc freq;
 table QUOTE_CONVERSION_STATUS*QUOTE_APPROVAL_LEVEL;
run;
proc freq;
  table MARKET_SEGMENT;
run;
proc freq;
  table COMPETITOR;
run;
proc freq;
  table SEC_REGION;
run;
proc logistic desc;
  class MARKET_SEGMENT SEC_REGION; 
  model converted = MARKET_SEGMENT SEC_REGION competition DISCOUNT2 discount3;
run;

/* Process 2 */

libname Q '';

data TI;
 set Q.TI;
 if QUOTE_CONVERSION_STATUS eq 'CONVERTED' then Converted = 1; else Converted=0;
 if competitor eq "COMPETITOR DOESN'T EXIST" then competition=0; else competition=1;
 * srp = 'suggested retail price'; 
 discount1 =  TI_SRP_OFFER_PRICE_GC - NEGOTIATED_PRICE_GC;
 if SUGGESTED_CHANNEL_PRICE_GC>0 then discount2 = (SUGGESTED_CHANNEL_PRICE_GC - NEGOTIATED_PRICE_GC)/OTC; else discount2=.;
 if COMPETITOR_PRICE_GC>0 then discount3 = (COMPETITOR_PRICE_GC-NEGOTIATED_PRICE_GC)/OTC; else discount3=.;
 * Sole sourced†(S) - TI is only supplier. No competitor has anything similar;
 if MG1 eq 'S' then SoleSourced=1; else SoleSourced=0;
run;

proc sort; 
by legal_status; 
run;

proc freq;
  table QUOTE_APPROVAL_LEVEL;
  by legal_status;
run;

data TI;
 set TI;
 if QUOTE_APPROVAL_LEVEL='AUTO-APPROVED' then delete;
 if substr(QUOTE_APPROVAL_LEVEL,1,9) eq 'ESCALATED' then Escalated=1; else Escalated=0;
 discount4 =    VAR_TI_SRP_TO_COMPETITOR;
 concession1 =  VAR_TI_SRP_TO_REQRESALE;
 if legal_status = 'DI' then distributor=1; else distributor=0;
run;

proc freq;
  table escalated;
  by legal_status;
run;

proc means;
 var discount1 discount2 SUGGESTED_CHANNEL_PRICE_GC TI_SRP_OFFER_PRICE_GC NEGOTIATED_PRICE_GC;
run;

proc means;
 var discount2 VAR_TI_SRP_TO_COMPETITOR discount3;
 class legal_status;
run;

proc means;
 var VAR_TI_SRP_TO_COMPETITOR;
 class legal_status MG1;
run;

proc means;
 var VAR_TI_SRP_TO_REQRESALE;
 class legal_status MG1;
run;

proc glm data=TI;
  class MARKET_SEGMENT SEC_REGION; 
  model discount4 = MARKET_SEGMENT SEC_REGION competition distributor MARKET_SEGMENT*competition distributor*competition SoleSourced distributor*SoleSourced /solution;
run;

proc glm data=TI;
  class MARKET_SEGMENT SEC_REGION; 
  model discount2 = MARKET_SEGMENT SEC_REGION competition distributor MARKET_SEGMENT*competition distributor*competition SoleSourced  distributor*SoleSourced /solution;
run;

proc logistic desc;
  class MARKET_SEGMENT SEC_REGION; 
  model converted = MARKET_SEGMENT SEC_REGION competition SoleSourced discount4 concession1 escalated;
  by legal_status;
run;

proc logistic desc;
  class MARKET_SEGMENT SEC_REGION legal_status; 
  model escalated = legal_status MARKET_SEGMENT SEC_REGION competition SoleSourced discount4 discount4*legal_status;
run;

proc logistic desc;
  class MARKET_SEGMENT SEC_REGION ACCOUNT_CATEGORY; 
  model converted = ACCOUNT_CATEGORY ACCOUNT_CATEGORY*escalated MARKET_SEGMENT SEC_REGION competition SoleSourced discount2 escalated;
  by legal_status;
run;

proc sort;  
by escalated legal_status; 
run;

proc means; 
  var discount4 concession1 escalated;
  class legal_status;
run;

proc means;
 var COMPETITOR_PRICE_GC;
run;

proc contents;
run;

proc freq;
 table QUOTE_CONVERSION_STATUS*QUOTE_APPROVAL_LEVEL;
run;

proc freq;
  table MARKET_SEGMENT;
run;

proc freq;
  table COMPETITOR;
run;

proc freq;
  table SEC_REGION;
run;

proc logistic desc;
  class MARKET_SEGMENT SEC_REGION; 
  model converted = MARKET_SEGMENT SEC_REGION competition SoleSourced DISCOUNT2 discount3;
run;

proc logistic desc;
  class MARKET_SEGMENT SEC_REGION; 
  model escalated = MARKET_SEGMENT SEC_REGION competition SoleSourced DISCOUNT2 discount3;
run;


/* Process 3*/

libname Q '';

data TI;
 set Q.TI;
 NegotiatedPrice = NEGOTIATED_PRICE_GC;
 SuggestedPriceForOE = SRP_CUSTOMER_PRODUCT_PRICE_GC;
 RequestedPriceByCustomer = REQUESTED_COST_GC;
 RequestedPrice = RequestedPriceByCustomer;
 if QUOTE_CONVERSION_STATUS eq 'CONVERTED' then Converted = 1; else Converted=0;
 if competitor eq "COMPETITOR DOESN'T EXIST" then competition=0; else competition=1;
 * srp = 'suggested retail price'; 
 discount1 =  TI_SRP_OFFER_PRICE_GC - NEGOTIATED_PRICE_GC;
 if legal_status = 'DI' then SuggestedPrice = SUGGESTED_CHANNEL_PRICE_GC; 
 if legal_status = 'OE' then SuggestedPrice = SRP_CUSTOMER_PRODUCT_PRICE_GC;
 if SuggestedPrice>0 then discount2 = (SuggestedPrice - NEGOTIATED_PRICE_GC)/OTC; else discount2=.;

 AcceptableFirstOffer = PA_LOWBALL_PRICE_GC;

 BargainRoom = 1- AcceptableFirstOffer/SuggestedPrice; 
 if AcceptableFirstOffer=0 or BargainRoom>1 or SuggestedPrice=0 then BargainRoom=.;
* if OTC<0.05 and SuggestedPrice>2 then delete;

 NegotiatedRequestedDiff = (NegotiatedPrice-RequestedPrice);
 SuggestedRequestedDiff = (suggestedPrice-RequestedPrice);

if COMPETITOR_PRICE_GC>0 then discount3 = (COMPETITOR_PRICE_GC-NEGOTIATED_PRICE_GC)/OTC; else discount3=.;
 * Sole sourced†(S) - TI is only supplier. No competitor has anything similar;
 if MG1 eq 'S' then SoleSourced=1; else SoleSourced=0;
run;

proc sort; 
by legal_status; 
run;

proc freq;
  table QUOTE_APPROVAL_LEVEL;
  by legal_status;
run;


data TI;
 set TI;
 if QUOTE_APPROVAL_LEVEL='AUTO-APPROVED' then delete;
 if substr(QUOTE_APPROVAL_LEVEL,1,9) eq 'ESCALATED' then Escalated=1; else Escalated=0;
 discount4 =    VAR_TI_SRP_TO_COMPETITOR;
 concession1 =  VAR_TI_SRP_TO_REQRESALE;
 if legal_status = 'DI' then distributor=1; else distributor=0;
run;


Data TI_Bargain;
 set TI;
* if legal_status = 'OE';
 if SuggestedPrice=0 or RequestedPrice=0 then delete;
 if  NegotiatedPrice > SuggestedPrice then ReverseBargaining=1; else ReverseBargaining=0;
 if NegotiatedRequestedDiff<0 or SuggestedRequestedDiff<=0.001 then delete;
 if RequestedPrice>0;
 if SuggestedPrice>0;
run;
data TI_Bargain;
 set TI_Bargain;
   BargainingPower = (NegotiatedPrice-RequestedPrice)/(SuggestedPrice - RequestedPrice);
   BPower = (NegotiatedPrice)/(SuggestedPrice);
run;

proc means data=TI_Bargain;
 var BargainingPower NegotiatedRequestedDiff SuggestedRequestedDiff RequestedPrice SuggestedPrice NegotiatedPrice;
 class ACCOUNT_CATEGORY;
run;

proc means data=TI_Bargain;
 var BargainingPower Bpower ReverseBargaining;
 class QUOTE_TYPE;
 by legal_status;
run;

proc means data=TI_Bargain;
 *var BargainingPower Bpower ReverseBargaining;
  var BargainingPower;
 class ACCOUNT_CATEGORY;
 by legal_status;
run;

proc means data=TI_Bargain;
  var converted;
 class ACCOUNT_CATEGORY;
 by legal_status;
run;

** Are prices too aggressive for Priority 2 customers?;
proc means data=TI_Bargain;
 *var BargainingPower Bpower ReverseBargaining;
  var BargainRoom;
 class ACCOUNT_CATEGORY;
 by legal_status;
run;

proc logistic desc;
  class MARKET_SEGMENT SEC_REGION ACCOUNT_CATEGORY legal_status; 
  model converted = ACCOUNT_CATEGORY|legal_status MARKET_SEGMENT SEC_REGION competition SoleSourced BargainingPower;
run;

proc logistic desc;
  class MARKET_SEGMENT SEC_REGION ACCOUNT_CATEGORY legal_status; 
  model converted = ACCOUNT_CATEGORY|legal_status MARKET_SEGMENT SEC_REGION competition SoleSourced BargainRoom;
run;

proc logistic desc;
  class MARKET_SEGMENT SEC_REGION ACCOUNT_CATEGORY legal_status; 
  model escalated = ACCOUNT_CATEGORY|legal_status MARKET_SEGMENT SEC_REGION competition SoleSourced BargainRoom;
run;

proc logistic desc;
  class MARKET_SEGMENT SEC_REGION ACCOUNT_CATEGORY legal_status; 
  model escalated = ACCOUNT_CATEGORY|legal_status MARKET_SEGMENT SEC_REGION competition SoleSourced BargainingPower;
run;

proc corr;
 var BargainingPower BargainRoom;
run;
