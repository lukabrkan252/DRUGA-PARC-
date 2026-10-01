with datumkpla (rn,datum,MTO)

as (
select distinct t0.DocNum,min(t5.ShipDate), T3.U_BXPMTOSc

from  OWOR t0    inner join   [@BXPMTOORDRSOLREF]  T3 on t3.U_BXPWODcN = t0.DocNum
                 inner join OITM t1 on t1.ItemCode = t0.ItemCode
                 inner join ORDR t4 on t4.DocNum = t3.U_BXPSODcN 
                 inner join RDR1 t5 on t5.DocEntry = t4.DocEntry and t3.U_BXPSOLin = t5.LineNum
where t3.U_BXPParWR is null

group by t0.DocNum, T3.U_BXPMTOSc




)


---OVAJ DATUM KORISTIMO UKOLIKO JE IZBRISANO IZ VARIATEC TABELE ZBOG OTVARANJA NALOGA
, datumkpla1 (rn,datum)

as (

select distinct t0.DocNum,min(t5.ShipDate)

from  OWOR t0    
                
				 inner join RDR1 t5 on t5.U_BXPMTOSc = t0.U_BXPMTOSc
                 inner join ORDR t4 on t5.DocEntry = t4.DocEntry 

group by t0.DocNum


)



, datumpozicije (rn,datum)

as (


select distinct t0.DocNum,min(t5.ShipDate)


from  OWOR t0    inner join   [@BXPMTOORDRSOLREF]  T3 on t3.U_BXPWODcN = t0.DocNum
                 inner join OITM t1 on t1.ItemCode = t0.ItemCode
                 inner join ORDR t4 on t4.DocNum = t3.U_BXPSODcN 
                 inner join RDR1 t5 on t5.DocEntry = t4.DocEntry and t3.U_BXPSOLin = t5.LineNum

where t3.U_BXPParWR is not null

group by t0.DocNum


)


, Trebovanje ( Radninalog, Planirano_materijala,Istrebovano_materijala )  


as (


select 

t0.DocNum ,  sum(t1.PlannedQty)  'Planirano materijala' , sum(t1.IssuedQty) 'Istrebovano materijala'

from dbo.owor t0 

inner join dbo.wor1 t1 on t1.DocEntry = t0.DocEntry 


where t1.wareHouse = 'skl03'

group by t0.DocNum )


,Čekiratalinija ( Radninalog,BXID )  

as (

select  t0.DocNum ,  MAX(t2.U_BXPPrOOI) 

from dbo.owor t0 

inner join dbo.wor1 t1 on t1.DocEntry = t0.DocEntry 

INNER join [@BXPPDCBOOKING] t2 on t1.U_BXPBxID = t2.U_BXPPrOOI 

where (t1.wareHouse = '01' OR t1.wareHouse = '02')  and (t1.ItemCode ='OP100' OR T1.[ItemCode]='OP200' OR T1.[ItemCode]='OP1200' OR t1.ItemCode = 'OP16400' OR t1.ItemCode = 'OP16500'OR t1.ItemCode = 'OP17200' OR t1.ItemCode = 'OP17300' OR t1.ItemCode = 'OP17400' OR t1.ItemCode = 'OP20400'  OR T1.[ItemCode]='OP3400'  OR T1.[ItemCode]='OP3800' )

group by t0.DocNum   )


, Čekirato ( Radninalog,BXID,Količina  )  

as (


select  t0.DocNum ,t2.BXID,sum(t3.U_BXPCoQty)

from dbo.owor t0 

inner join dbo.wor1 t1 on t1.DocEntry = t0.DocEntry 

INNER join Čekiratalinija t2 on t2.BXID = t1.U_BXPBxID 
INNER join [@BXPPDCBOOKING] t3 on t1.U_BXPBxID = t3.U_BXPPrOOI 

where (t1.wareHouse = '01' OR t1.wareHouse = '02') and (t1.ItemCode ='OP100' OR T1.[ItemCode]='OP200' OR T1.[ItemCode]='OP1200' OR t1.ItemCode = 'OP16400'OR t1.ItemCode = 'OP16500' OR t1.ItemCode = 'OP17200' OR t1.ItemCode = 'OP17300' OR t1.ItemCode = 'OP17400' OR t1.ItemCode = 'OP20400' OR T1.[ItemCode]='OP3400'  OR T1.[ItemCode]='OP3800' )

group by t0.DocNum   ,t2.BXID


)


, OPISOPERACIJE (RN,OPIS )

AS (

SELECT  T0.DocNum,
cast (T2.U_BXPOpDsc as nvarchar (max))

  FROM OWOR T0 INNER JOIN WOR1 T1 ON T0.DocEntry = T1.DocEntry 
  inner JOIN [@BXPPRODORDEROPER]  T2 ON T2.U_BXPPrODE = T0.DocEntry AND 
  T2.Code = T1.U_BXPBxID 
  
  where t1.ItemCode = 'op600' and  (T0.Status = 'R' or T0.Status = 'P')
  
  
 
)






, materijalponalogu (RN,Item,Nazivmaterijala)

as 

( 

select T0.DocNum'RN',T0.ItemCode'Item',t2.ItemName'Naziv Materijala'

from OWOR t0 inner join WOR1 t1 on
T0.DocEntry = T1.DocEntry
inner join OITM t2 on t1.ItemCode = t2.ItemCode 

WHERE T1.wareHouse= 'SKL03'   and     (T0.Status = 'R' or T0.Status = 'P')



GROUP BY T0.DocNum,T0.ItemCode,t2.ItemName 

),
  potrebetestereiplazme (RN1,Item1,testeraiplazma) 
as
(
select  t0.DocNum'RN1',T0.ItemCode'Item1',
CASE WHEN T1.ItemCode ='OP600' THEN 'REZANJE TESTEROM' WHEN (T1.ItemCode = 'OP1600' OR t1.ItemCode = 'OP16600' OR t1.ItemCode = 'OP16700' ) THEN 'SJECENJE PLAZMOM'  END as 'testeraiplazma'
 
from OWOR t0 inner join WOR1 t1 on
T0.DocEntry = T1.DocEntry
             

where t1.ItemCode = 'OP600' OR t1.ItemCode = 'OP1600'  and    (T0.Status = 'R' or T0.Status = 'P')



group by t0.DocNum,t0.ItemCode,t1.ItemCode
  
)

, norma ( Rn, Item,Norma,Normamasinske,IstrebovanaNormamasinske ,Linija)

as( 


select t0.DocNum,t0.ItemCode,t1.PlannedQty

, CASE when T1.[ItemCode]='OP100' OR T1.[ItemCode]='OP200' OR T1.[ItemCode]='OP1200'  OR t1.ItemCode = 'OP17200' OR t1.ItemCode = 'OP17300' OR t1.ItemCode = 'OP16400' OR t1.ItemCode = 'OP16500' OR t1.ItemCode = 'OP17400' OR t1.ItemCode = 'OP20400' OR T1.[ItemCode]='OP3400'  OR T1.[ItemCode]='OP3800'  then t1.PlannedQty end as 'Normamasinske'
, CASE when T1.[ItemCode]='OP100' OR T1.[ItemCode]='OP200' OR T1.[ItemCode]='OP1200'  OR t1.ItemCode = 'OP17200' OR t1.ItemCode = 'OP17300' OR t1.ItemCode = 'OP16400' OR t1.ItemCode = 'OP16500' OR t1.ItemCode = 'OP17400' OR t1.ItemCode = 'OP20400' OR T1.[ItemCode]='OP3400'  OR T1.[ItemCode]='OP3800'  then t1.IssuedQty end as 'Istrebovana Norma masinske'

,t1.LineNum 'Linija'


from owor t0 inner join wor1 t1 on t1.docentry  = t0.docentry
  

group by t0.DocNum,t0.ItemCode,t1.PlannedQty,T1.[ItemCode],t1.LineNum,t1.IssuedQty

)


, KPL_PO_SCENARIJU AS
(
    SELECT
        D.MTO,
        STUFF(
            (
                SELECT ';' + CAST(D2.rn AS varchar(20))
                FROM datumkpla D2
                WHERE D2.MTO = D.MTO
                ORDER BY D2.rn
                FOR XML PATH(''), TYPE
            ).value('.', 'varchar(max)')
        ,1,1,'') AS KPL_RN
    FROM datumkpla D
    GROUP BY D.MTO
)


  
SELECT 



t100.KPL_RN 'KPL RN',T0.DocNum 'RN',t5.ItemName'Naziv',Nazivmaterijala,T0.[PlannedQty] 'Planirano',
MIN(CASE WHEN (T1.[ItemCode]='OP100' OR T1.[ItemCode]='OP200' OR T1.[ItemCode]='OP1200' OR T1.[ItemCode]='OP300' 
OR T1.[ItemCode]='OP3400' OR T1.[ItemCode]= 'op500'  OR T1.[ItemCode]= 'op900' OR T1.[ItemCode]= 'op2300' 
OR T1.[ItemCode]= 'op3300' OR T1.[ItemCode]= 'op3500' OR T1.[ItemCode]= 'op2600' OR T1.[ItemCode]= 'op2900' 
OR T1.[ItemCode]= 'op700' OR T1.[ItemCode]= 'op2200' OR T1.[ItemCode]= 'op3400' OR T1.[ItemCode]= 'op2700' 
OR T1.[ItemCode]= 'op3000' OR T1.[ItemCode]= 'op2400' OR T1.[ItemCode]= 'op3200' OR T1.[ItemCode]= 'op3100' 
or T1.[ItemCode]='op3800' OR T1.[ItemCode]='OP3900' OR T1.[ItemCode]='OP10400'	OR
T1.[ItemCode]=	'OP12500'	OR
T1.[ItemCode]=	'OP12400'	OR
T1.[ItemCode]=	'Op12200'	OR
T1.[ItemCode]=	'OP12100'	OR
T1.[ItemCode]=	'OP11800'	OR
T1.[ItemCode]=	'OP6000'	OR
T1.[ItemCode]=	'OP6100'	OR
T1.[ItemCode]=	'OP6200'	OR
T1.[ItemCode]=	'OP6300'	OR
T1.[ItemCode]=	'OP6400'	OR
T1.[ItemCode]=	'OP6500'	OR
T1.[ItemCode]=	'OP6600'	OR
T1.[ItemCode]=	'OP6700'	OR
T1.[ItemCode]=	'OP6800'	OR
T1.[ItemCode]=	'OP6900'	OR
T1.[ItemCode]=	'OP7000'	OR
T1.[ItemCode]=	'OP7100'	OR
T1.[ItemCode]=	'OP7200'	OR
T1.[ItemCode]=	'OP7300'	OR
T1.[ItemCode]=	'OP7400'	OR
T1.[ItemCode]=	'OP7500'	OR
T1.[ItemCode]=	'OP7600'    OR 
t1.ItemCode = 'OP16400' or
t1.ItemCode = 'OP16500' or
t1.ItemCode = 'OP17200'     OR 
t1.ItemCode = 'OP17300'	    OR 
t1.ItemCode = 'OP17400'		OR 
t1.ItemCode = 'OP20400') THEN 'MASINSKA OBRADA' ELSE 'NEMA MASINSKE OBRADE' END ) AS 'MASINSKA',

T0.ItemCode'Sifra Proizvoda', T0.[CmpltQty]+T0.[RjctQty] 'Zavrseno',T0.[PlannedQty] - (T0.[CmpltQty] + T0.[RjctQty]) 'U izradi',testeraiplazma,

t0.U_BXPMTOSc'MTO Scenario', CASE WHEN T0.[U_BXPProdSkart]='2' THEN 'DORADNI NALOG' WHEN T0.[U_BXPProdSkart]='1' THEN 'SKARTNI NALOG' END AS 'Dorada i skart' ,CAST(t6.OPIS AS nvarchar(max)) as 'Opis Operacije'

,case when T0.Status = 'r' then 'Otvoren' when T0.Status = 'p' then 'Planirano' when T0.Status = 'c' then 'Cancelled' when T0.Status = 'l' then 'Zatvoren'  end as 'Status'  ,t0.Warehouse,

Case when t7.datum IS null and t9.datum is not null then t9.datum 

WHEN (t7.datum IS NULL and T9.datum IS NULL ) 

THEN T99.datum   else t7.datum  end  as 'Datum isporuke'



,t8.Planirano_materijala,t8.Istrebovano_materijala,

CASE

WHEN t5.U_Projekt = '1' THEN 'GROB'
WHEN t5.U_Projekt = '2' THEN 'FFT'
WHEN t5.U_Projekt = '3' THEN 'Thyssen'
WHEN t5.U_Projekt = '4' THEN 'EFCO'
WHEN t5.U_Projekt = '5' THEN 'LIEBHER'
WHEN t5.U_Projekt = '6' THEN 'DIOSNA'
WHEN t5.U_Projekt = '7' THEN 'WUH'
WHEN t5.U_Projekt = '8' THEN 'MESSER'
WHEN t5.U_Projekt = '9' THEN 'KOIKE'
WHEN t5.U_Projekt = '10' THEN 'SATO'
WHEN t5.U_Projekt = '11' THEN 'KAMPF'
WHEN t5.U_Projekt = '12' THEN 'BICIKLA'
WHEN t5.U_Projekt = '13' THEN 'BOMBARDIER'
WHEN t5.U_Projekt = '14' THEN 'KNORR BREMSSE'
WHEN t5.U_Projekt = '15' THEN 'SALVAGNINI'
WHEN t5.U_Projekt = '16' THEN 'MGM'
WHEN t5.U_Projekt = '17' THEN 'VAG'
WHEN t5.U_Projekt = '18' THEN 'Doppstadt'
WHEN t5.U_Projekt = '19' THEN 'ZIENSER'
WHEN t5.U_Projekt = '20' THEN 'SPRINGER'
WHEN t5.U_Projekt = '21' THEN 'SAWO'
WHEN t5.U_Projekt = '22' THEN 'SCC INDUSTRY'
WHEN t5.U_Projekt = '23' THEN 'POBJEDA TEŠANJ'
WHEN t5.U_Projekt = '24' THEN 'GOEBEL-IMS'
WHEN t5.U_Projekt = '25' THEN 'ALATI'
WHEN t5.U_Projekt = '26' THEN 'CINCINNATI'
WHEN t5.U_Projekt = '27' THEN 'SMED'
WHEN t5.U_Projekt = '28' THEN 'BOBST'
WHEN t5.U_Projekt = '29' THEN 'ANDRITZ'
WHEN t5.U_Projekt = '30' THEN 'HF MIXING GROUP'
WHEN t5.U_Projekt = '31' THEN 'ENEK B&E'
WHEN t5.U_Projekt = '32' THEN 'SCHEFFER'
WHEN t5.U_Projekt = '33' THEN 'MITTAL ZENICA'
WHEN t5.U_Projekt = '34' THEN 'BHS'
WHEN t5.U_Projekt = '35' THEN 'ODRZAVANJE'
WHEN t5.U_Projekt = '36' THEN 'TEH-CUT'
WHEN t5.U_Projekt = '37' THEN 'BOBST MEX'
WHEN t5.U_Projekt = '38' THEN 'SIEMENS'
WHEN t5.U_Projekt = '39' THEN 'HIDROENERGIJA'
WHEN t5.U_Projekt = '40' THEN 'EROWA'
WHEN t5.U_Projekt = '41' THEN 'ATS'
WHEN t5.U_Projekt= '42' THEN 'PMP Jelsingrad'
WHEN t5.U_Projekt = '43' THEN 'CHIRON' 
WHEN t5.U_Projekt = '44' THEN 'PHLEGON-SOLAR' 
WHEN t5.U_Projekt = '45' THEN 'HELLER' 
WHEN t5.U_Projekt = '46' THEN 'HF NaJUS' 
WHEN t5.U_Projekt = '47' THEN 'Remmel AG' 
WHEN t5.U_Projekt = '48' THEN 'GOLDHOFER' 
WHEN t5.U_Projekt= '49' THEN 'KOSTWEIN MASCHINENBAU GMBH' 
WHEN t5.U_Projekt = '50' THEN 'Klingelnberg' 
WHEN t5.U_Projekt = '51' THEN 'SCHAUENBURG' 
WHEN t5.U_Projekt = '52' THEN 'Kaltenbach' 
WHEN t5.U_Projekt = '53' THEN 'PROGRESYS' 
WHEN t5.U_Projekt = '54' THEN 'Dexpro' 
WHEN t5.U_Projekt = '55' THEN 'Oskar Frech'
WHEN t5.U_Projekt = '56' THEN 'NEUENHAUSER' 
WHEN t5.U_Projekt = '57' THEN 'Razvoj NP' 
WHEN t5.U_Projekt = '58' THEN 'VIOLETA' 
WHEN t5.U_Projekt = '59' THEN 'C Technik'
WHEN t5.U_Projekt = '60' THEN 'STAMEN' 
WHEN t5.U_Projekt = '61' THEN 'DMG MORI' 
WHEN t5.U_Projekt = '62' THEN 'LINDNER' 
WHEN t5.U_Projekt = '63' THEN 'Niehoff' 
WHEN t5.U_Projekt = '64' THEN 'ZECK' 
WHEN t5.U_Projekt = '65' THEN 'Bruks' 
WHEN t5.U_Projekt = '66' THEN 'VOITH HYDRO BOSNIA' 
WHEN t5.U_Projekt = '67' THEN 'HAENDLE' 
WHEN t5.U_Projekt = '68' THEN 'ALMY' 
WHEN t5.U_Projekt = '69' THEN 'Maksut' 
WHEN t5.U_Projekt = '70' THEN 'Metron' 
WHEN t5.U_Projekt = '71' THEN 'Ruff SEE'
WHEN t5.U_Projekt = '72' THEN 'Schwing' 
WHEN t5.U_Projekt = '73' THEN 'Stadler'
WHEN t5.U_Projekt = '74' THEN 'Schuler' 
WHEN t5.U_Projekt = '75' THEN 'Kramer-Werke' 
WHEN t5.U_Projekt = '76' THEN 'Grenzebach' 
WHEN t5.U_Projekt = '77' THEN 'SIAC Krupa kabine'

END AS 'PROJEKT',t10.Količina 'Čekirano',sum(t11.Normamasinske) 'Norma na masinskoj'


FROM OWOR T0 inner join WOR1 t1 on
T0.DocEntry = T1.DocEntry
LEFT JOIN materijalponalogu  ON T0.DocNum = RN
left join potrebetestereiplazme on t0.DocNum = RN1 
inner join OITM t5 on t0.ItemCode = t5.ItemCode
LEFT JOIN OPISOPERACIJE T6 ON T6.RN = T0.DocNum
left join datumkpla t7 on t7.rn = t0.DocNum
left join Trebovanje t8 on t8.Radninalog = t0.DocNum
left join datumpozicije t9 on t9.rn = t0.DocNum
left join Čekirato t10 on t10.Radninalog = t0.DocNum
left join norma t11 on t11.Rn = t0.DocNum and t1.LineNum = t11.Linija
LEFT JOIN datumkpla1 T99 ON T99.rn = T0.DOCNUM
left join KPL_PO_SCENARIJU t100 on t100.MTO = t0.U_BXPMTOSc


Where  

(T0.Status = 'R' or T0.Status = 'P')



GROUP BY T0.DocNum,  T0.ItemCode,Nazivmaterijala,testeraiplazma,t5.ItemName,T0.[PlannedQty],T0.CmpltQty,T0.[RjctQty],t0.U_BXPMTOSc,T0.[U_BXPProdSkart],  t100.KPL_RN, --T99.rn ,


CAST(t6.OPIS AS nvarchar(max)) ,T0.Status,t0.Warehouse,t7.datum,t8.Planirano_materijala,t8.Istrebovano_materijala,t5.U_Projekt,t9.datum,t10.Količina , T99.datum


order by T0.DocNum