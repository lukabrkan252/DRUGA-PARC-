-----Projekt na nalogu



create table  #Projekt  ( MTO nvarchar(max),Item nvarchar(max),Projekt nvarchar(max) )
insert into   #Projekt  (MTO ,Item,Projekt)

select T0.U_BXPMTOSc,t0.U_BXPItmCd, CASE WHEN t2.U_Projekt = '1' THEN 'GROB' 
WHEN t2.U_Projekt = '2'  THEN 'FFT'
WHEN t2.U_Projekt = '3'  THEN 'Thyssen'
WHEN t2.U_Projekt = '4'  THEN 'EFCO'
WHEN t2.U_Projekt = '5'  THEN 'LIEBHER'
WHEN t2.U_Projekt = '6'  THEN 'DIOSNA'
WHEN t2.U_Projekt = '7'  THEN 'WUH'
WHEN t2.U_Projekt = '8'  THEN 'MESSER'
WHEN t2.U_Projekt = '9'  THEN 'KOIKE'
WHEN t2.U_Projekt = '10' THEN 'SATO'
WHEN t2.U_Projekt = '11' THEN 'KAMPF'
WHEN t2.U_Projekt = '12' THEN 'BICIKLA'
WHEN t2.U_Projekt = '13' THEN 'BOMBARDIER'
WHEN t2.U_Projekt = '14' THEN 'KNORR BREMSSE'
WHEN t2.U_Projekt = '15' THEN 'SALVAGNINI'
WHEN t2.U_Projekt = '16' THEN 'MGM'
WHEN t2.U_Projekt = '17' THEN 'WAG'
WHEN t2.U_Projekt = '18' THEN 'Doppstadt'
WHEN t2.U_Projekt = '19' THEN 'ZIENSER' 
WHEN t2.U_Projekt = '20' THEN 'Springer'
WHEN t2.U_Projekt = '21' THEN 'Sawo'
WHEN t2.U_Projekt = '22' THEN 'SCC INDUSTRY'
WHEN t2.U_Projekt = '23' THEN 'POBJEDA TEŠANJ'
WHEN t2.U_Projekt = '24' THEN 'GOEBEL-IMS'
WHEN t2.U_Projekt = '25' THEN 'ALATI'
WHEN t2.U_Projekt = '26' THEN 'CINCINNATI'
WHEN t2.U_Projekt = '27' THEN 'SMED'
WHEN t2.U_Projekt = '28' THEN 'BOBST'
WHEN t2.U_Projekt = '29' THEN 'ANDRITZ'
WHEN t2.U_Projekt = '30' THEN 'HF MIXING GROUP'
WHEN t2.U_Projekt = '31' THEN 'ENEK B&E'
WHEN t2.U_Projekt = '32' THEN 'SCHEFFER'
WHEN t2.U_Projekt = '33' THEN 'MITTAL ZENICA'
WHEN t2.U_Projekt = '34' THEN 'BHS'
WHEN t2.U_Projekt = '35' THEN 'Odrzavanje'
WHEN t2.U_Projekt = '36' THEN 'Teh-cut'
WHEN t2.U_Projekt = '37' THEN 'BOBST MEX'
WHEN t2.U_Projekt = '38' THEN 'SIEMENS'
WHEN t2.U_Projekt = '39' THEN 'HIDROENERGIJA'
WHEN t2.U_Projekt = '40' THEN 'EROWA'
WHEN t2.U_Projekt = '41' THEN 'ATS'
WHEN t2.U_Projekt = '42' THEN 'PMP Jelsingrad'
WHEN T2.U_Projekt = '43' THEN 'CHIRON'
WHEN T2.U_Projekt = '44' THEN 'PHLEGON-SOLAR'
WHEN T2.U_Projekt = '45' THEN 'HELLER'
WHEN t2.U_Projekt  = '46' THEN 'HF NaJUS'
WHEN t2.U_Projekt  = '47' THEN 'Remmel AG'
WHEN t2.U_Projekt = '48' THEN 'GOLDHOFER'
WHEN t2.U_Projekt = '49' THEN 'KOSTWEIN MASCHINENBAU GMBH'
WHEN t2.U_Projekt = '50' THEN 'Klingelnberg'
WHEN t2.U_Projekt = '51' THEN 'SCHAUENBURG'
WHEN t2.U_Projekt = '52' THEN 'Kaltenbach'
WHEN t2.U_Projekt = '53' THEN 'PROGRESYS'
WHEN t2.U_Projekt = '54' THEN 'Dexpro'
WHEN t2.U_Projekt = '55' THEN 'Oskar Frech' 
WHEN t2.U_Projekt = '56' THEN 'NEUENHAUSER' 
WHEN t2.U_Projekt = '57' THEN 'Razvoj NP' 
WHEN t2.U_Projekt = '58' THEN 'VIOLETA'
WHEN t2.U_Projekt = '59' THEN 'C Technik'
WHEN t2.U_Projekt = '60' THEN 'STAMEN' 
WHEN t2.U_Projekt = '61' THEN 'DMG MORI' 
WHEN t2.U_Projekt = '62' THEN 'LINDNER'
WHEN t2.U_Projekt = '63' THEN 'Niehoff' 
WHEN t2.U_Projekt = '64' THEN 'ZECK' 
WHEN t2.U_Projekt = '65' THEN 'Bruks' 
WHEN t2.U_Projekt = '66' THEN 'VOITH HYDRO BOSNIA' 
WHEN t2.U_Projekt = '67' THEN 'HAENDLE' 
WHEN t2.U_Projekt = '68' THEN 'ALMY' 
WHEN t2.U_Projekt = '69' THEN 'Maksut'
WHEN t2.U_Projekt = '70' THEN 'Metron' 
WHEN t2.U_Projekt = '71' THEN 'Ruff SEE'
WHEN t2.U_Projekt = '72' THEN 'Schwing' 
WHEN t2.U_Projekt = '73' THEN 'Stadler' 
WHEN t2.U_Projekt = '74' THEN 'Schuler' 
WHEN t2.U_Projekt = '75' THEN 'Kramer-Werke'

END AS 'PROJEKT' 

from [@BXPMTOORDRSOLREF] t0 with (nolock) inner join OITM t2 with (nolock) on t0.U_BXPItmCd = t2.ItemCode
where t0.U_BXPParWR is null 
GROUP BY T0.U_BXPMTOSc,t0.U_BXPItmCd,t2.U_Projekt  





---------Posmatramo samo scenarije koji imaju otvoren Sales Order
create table #Open_MTO (MTO nvarchar(max))
insert into #Open_MTO (MTO)

select DISTINCT T1.U_BXPMTOSc from ordr T0 with (nolock) INNER JOIN RDR1 T1 with (nolock) ON T1.DocEntry = T0.DocEntry 
WHERE T1.LineStatus = 'O' 

  


--------Tbela sa glavnim podacima i funkcijom za kalkulaciju preostalog vremena
create table #PREOSTALANORMA (RN nvarchar(max),PROJEKT nvarchar(max),NazivProizvoda nvarchar(max),Naziv nvarchar(max) ,Planirano decimal (18,2),Utrosenovremena decimal (18,2)  ,Ostalovremena decimal (18,2) ,Planiranokomadaponalogu decimal (18,2),Zavrsenokomadaponalogu decimal (18,2),Cekirano decimal (18,2),OPopis nvarchar(max),Linija int,Masina nvarchar(max),MTO  nvarchar(max),Mailstone nvarchar(max),Baseqty decimal (18,2) ) 
insert into #PREOSTALANORMA (RN,PROJEKT,NazivProizvoda,Naziv,Planirano,Utrosenovremena,Ostalovremena ,Planiranokomadaponalogu,Zavrsenokomadaponalogu,Cekirano,OPopis,Linija,Masina,MTO,Mailstone,Baseqty) 


select  

t0.DocNum, T70.Projekt ,t8.ItemName 'Naziv Proizvoda',t9.ItemName 'Naziv', t1.PlannedQty 'Planirano' ,t10.Result * t1.BaseQty 'Utroseno vremena',

t1.PlannedQty - (t10.Result * t1.BaseQty)  'Ostalovremena' ,

t0.PlannedQty 'Planirano komada po nalogu',

t10.Zavrseno 'Završeno komada po nalogu'  ,t10.Result 'Cekirano', CAST(T3.[U_BXPOpDsc] AS NVARCHAR(4000)) 'OPopis' ,t10.LineOrder + 1  'Linija',t2.U_BXPPrfWC  'Masina' ,T0.U_BXPMTOSc 'MTO'

, CASE WHEN t1.ItemCode LIKE 'OP400' OR
                                t1.ItemCode LIKE 'OP3900' OR
                                t1.ItemCode LIKE 'OP10800' OR
                                t1.ItemCode LIKE 'OP10900' OR
                                t1.ItemCode LIKE 'OP11000' OR
                                t1.ItemCode LIKE 'OP11100' OR
                                t1.ItemCode LIKE 'OP11200' OR
                                t1.ItemCode LIKE 'OP19000' /*--OR t1.ItemCode like 'OP11500'*/ THEN 'Farbanje' WHEN ((t1.ItemCode LIKE 'op1800' OR
                                t1.ItemCode LIKE 'op1800-1' OR
                                t1.ItemCode LIKE 'OP7700' OR
                                t1.ItemCode LIKE 'OP7800' OR
                                t1.ItemCode LIKE 'OP7900' OR
                                t1.ItemCode LIKE 'OP9600' OR
                                t1.ItemCode LIKE 'OP9700' OR
                                t1.ItemCode LIKE 'OP8700' OR
                                t1.ItemCode LIKE 'OP8800' OR
                                t1.ItemCode LIKE 'OP8900' OR
                                t1.ItemCode LIKE 'OP9000' OR
                                t1.ItemCode LIKE 'OP9400' OR
                                t1.ItemCode LIKE 'OP8000' OR
                                t1.ItemCode LIKE 'OP8100' OR
                                t1.ItemCode LIKE 'OP15300' OR
                                t1.ItemCode LIKE 'OP15400' OR
                                t1.ItemCode LIKE 'OP15500' OR
                                t1.ItemCode LIKE 'OP15600' OR
                                t1.ItemCode LIKE 'OP17500' OR
                                t1.ItemCode LIKE 'OP17600' OR
                                t1.ItemCode LIKE 'OP17700' OR
                                t1.ItemCode LIKE 'OP17800' OR
                                t1.ItemCode LIKE 'OP21800' OR
                                t1.ItemCode LIKE 'OP9100') OR
                                (t1.ItemCode LIKE 'op1700' OR
                                t1.ItemCode LIKE 'OP8400' OR
                                t1.ItemCode LIKE 'OP8500' OR
                                t1.ItemCode LIKE 'OP8600' OR
                                t1.ItemCode LIKE 'OP8200' OR
                                t1.ItemCode LIKE 'OP8300' OR
                                t1.ItemCode LIKE 'OP9800' OR
                                t1.ItemCode LIKE 'OP9900' OR
                                t1.ItemCode LIKE 'OP10000' OR
                                t1.ItemCode LIKE 'OP10100' OR
                                t1.ItemCode LIKE 'OP10200' OR
                                t1.ItemCode LIKE 'OP10300' OR
                                t1.ItemCode LIKE 'OP15700' OR
                                t1.ItemCode LIKE 'OP15800' OR
                                t1.ItemCode LIKE 'OP15900' OR
                                t1.ItemCode LIKE 'OP16000' OR
                                t1.ItemCode = 'OP18300' OR
                                t1.ItemCode = 'OP17900' OR
                                t1.ItemCode = 'OP18800' OR
                                t1.ItemCode = 'OP18000' OR
                                t1.ItemCode = 'OP18100' OR
                                t1.ItemCode = 'OP18200' OR
                                t1.ItemCode = 'OP14300' OR
                                t1.itemcode = 'OP21600' OR
                                /*t1.itemcode = 'op12800' or*/ t1.itemcode = 'op12700' OR
                                t1.itemcode = 'op10400')) THEN 'Heftanje - Zavarivanje' WHEN (T1.ItemCode = 'OP100' OR
                                T1.ItemCode = 'OP200' OR
                                T1.ItemCode = 'OP1200' OR
                                T1.ItemCode = 'OP3400' OR
                                T1.ItemCode = 'op500' OR
                                T1.ItemCode = 'op900' OR
                                T1.ItemCode = 'op2300' OR
                                T1.ItemCode = 'op3300' OR
                                T1.ItemCode = 'op3500' OR
                                T1.ItemCode = 'op2600' OR
                                T1.ItemCode = 'op2900' OR
                                T1.ItemCode = 'op700' OR
                                T1.ItemCode = 'op2200' OR
                                T1.ItemCode = 'op3400' OR
                                T1.ItemCode = 'op2700' OR
                                T1.ItemCode = 'op3000' OR
                                T1.ItemCode = 'op2400' OR
                                T1.ItemCode = 'op3200' OR
                                T1.ItemCode = 'op3100' OR
                                T1.ItemCode = 'op3800' OR
                                T1.ItemCode = 'OP12500' OR
                                T1.ItemCode = 'OP12400' OR
                                T1.ItemCode = 'Op12200' OR
                                T1.ItemCode = 'OP12100' OR
                                T1.ItemCode = 'OP11800' OR
                                T1.ItemCode = 'OP6000' OR
                                T1.ItemCode = 'OP6100' OR
                                T1.ItemCode = 'OP6200' OR
                                T1.ItemCode = 'OP6300' OR
                                T1.ItemCode = 'OP6400' OR
                                T1.ItemCode = 'OP6500' OR
                                T1.ItemCode = 'OP6600' OR
                                T1.ItemCode = 'OP6700' OR
                                T1.ItemCode = 'OP6800' OR
                                T1.ItemCode = 'OP6900' OR
                                T1.ItemCode = 'OP7100' OR
                                T1.ItemCode = 'OP7200' OR
                                T1.ItemCode = 'OP7300' OR
                                T1.ItemCode = 'OP7400' OR
                                T1.ItemCode = 'OP7500' OR
                                T1.ItemCode = 'OP7600' OR
                                T1.ItemCode = 'OP17200' OR
                                T1.ItemCode = 'OP17400' OR
                                T1.ItemCode = 'OP16500' OR
	                  T1.ItemCode = 'OP22100' OR
                                t1.itemcode = 'op7000') THEN 'MO' WHEN T1.ItemCode = 'OP5600' THEN 'Pakovanje' WHEN t1.ItemCode = 'OP1900' THEN 'Zarenje' WHEN t1.ItemCode = 'op10500' THEN 'Brusenje' WHEN t1.ItemCode = 'OP1400' OR
                                t1.ItemCode = 'op12900' OR
                                t1.ItemCode = 'op11300' THEN 'Pjeskarenje' WHEN (t1.ItemCode = 'OP11700' OR
                                t1.ItemCode = 'OP5300' OR
                                t1.ItemCode = 'OP600' OR
                                t1.ItemCode = 'OP1600') THEN 'Priprema' ELSE 'Ostalo' END AS Mailstone, t1.BaseQty 





--1135452


from 

OWOR t0 with (nolock)   inner join WOR1 t1 with (nolock) on t0.DocEntry = t0.DocEntry
             inner join [@BXPPRODORDERREQU]  T2 with (nolock) on t2.U_BXPPrOOI  = t1.U_BXPBxID and t0.DocEntry = t2.U_BXPPrODE 
             inner join  [@BXPPRODORDEROPER] t3 with (nolock) on t3.Code = t1.U_BXPBxId 
             inner join OITM t8 with (nolock) on t0.ItemCode = t8.ItemCode 
             inner join OITM t9  with (nolock)on t1.ItemCode = t9.ItemCode 
             left join [dbo].[view_RecalculateCek_nermin_10092025] t10 on t10.nalogid  = t0.DocNum and t10.LineOrder =  t1.LineNum
			 
			 --outer apply dbo.func_RecalculateCek ( t0.U_BXPMTOSc, t0.Docnum) as t10   
             --LEFT JOIN   #Prvidatum T69 ON T0.U_BXPMTOSc  = T69.MTO  
            inner JOIN   #Projekt T70 ON T0.U_BXPMTOSc   =  T70.MTO  collate SQL_Latin1_General_CP1_CI_AS
			inner join #Open_MTO t71 on t71.MTO = t0.U_BXPMTOSc   collate SQL_Latin1_General_CP1_CI_AS
  
  --select * from [dbo].[view_RecalculateCek_nermin_10092025] t10 


where   t0.[Status]  = 'r'    and isnull(t8.U_Projekt,0) not like '12'  
  
and (t1.PlannedQty - (t10.Result * t1.BaseQty)> 0)  and  (t0.Warehouse not like 'skl305' and t0.Warehouse not like 'skl304' )   -- AND T0.U_BXPMTOSc = 'MTO_20250919102245'
    
group by T0.U_BXPMTOSc,T70.Projekt,t0.DocNum,t1.PlannedQty, t10.Result,t10.LineOrder ,t1.BaseQty,t9.ItemName,t8.ItemName,t2.U_BXPPrfWC, CAST(T3.[U_BXPOpDsc] AS NVARCHAR(4000)),t0.PlannedQty,t10.Zavrseno,t1.ItemCode
  




----------------------------------------------------------------------------Datumi sastavljanja-------------------------------------------------------------------------------------------------------------------------------------------------


;with Datumi_Sastavljanja_maxid(ID, SalesOrder, Linenum) AS
    (SELECT        MAX(Id) AS Expr1, SalesOrder, Line
      FROM            Logistika_Plan_Date.dbo.Edit_SalesOrderList
      GROUP BY SalesOrder, Line), 
	  


Datumi_Sastavljanja(SalesOrder, Linenum, DatumSastavljanja) AS
    (SELECT DISTINCT T0.SalesOrder, T0.Line - 1 AS Expr1, CASE WHEN t0.StartDate IS NULL THEN NULL WHEN t0.StartDate = '0001-01-01' THEN NULL ELSE t0.StartDate END AS Datum

      FROM            Logistika_Plan_Date.dbo.Edit_SalesOrderList AS T0 INNER JOIN
                                Datumi_Sastavljanja_maxid AS t1 ON t1.ID = T0.Id)






--------------------------------------------------------------------------Datumi Plana realizacije----------------------------------------


, RankedRealizacija AS (
    SELECT 
        t0.Id,
        t0.SAPSO,
        t0.Linija,
        t0.PlanRealizacije,
        ROW_NUMBER() OVER (
            PARTITION BY t0.SAPSO, t0.Linija 
            ORDER BY t0.Id DESC
        ) AS rn
    FROM [DB_GS-TMT_SSuite].[dbo].[KanBan_PlanRealizacije] t0
    WHERE t0.IsDeleted = 0
),
RealizacijaPlanMAXID AS (
    SELECT
        SAPSO,
        Linija,
        PlanRealizacije
    FROM RankedRealizacija
    WHERE rn = 1
)


, RealizacijaPlanDate as (

SELECT SAPSO , Linija, PlanRealizacije, t2.U_BXPMTOSc
FROM RealizacijaPlanMAXID t0
inner join ordr t1 on t1.DocNum = t0.SAPSO  
inner join RDR1 t2 on t2.DocEntry = t1.DocEntry and t2.LineNum = t0.Linija
)


,

---------------------------------------------Datum realizacije za naloge koji nisu sklopovi---------------------------

RealizacijaPlanDateGroup as (
 
select U_BXPMTOSc, MIN(PlanRealizacije) 'PlanRealizacije'  from RealizacijaPlanDate group by U_BXPMTOSc) 

--------------------------------------------------------------------------------------------------------------------------

, glavninalog ( Glavninalog1,Scenario, ShipDate,DatumSastavljanja, DatumPlanRealizacije )

as (

SELECT   t0.U_BXPWODcN  'Glavni nalog',  t0.U_BXPMTOSc 'Scenario' , t2.ShipDate, t3.DatumSastavljanja , t4.PlanRealizacije

FROM [dbo].[@BXPMTOORDRSOLREF]  T0 

inner join ordr t1 on t1.DocNum = t0.U_BXPSODcN  
inner join RDR1 t2 on t2.DocEntry = t1.DocEntry and t2.LineNum = t0.U_BXPSOLin
left join Datumi_Sastavljanja t3 on t3.SalesOrder = t1.DocNum and t3.Linenum = t2.LineNum
left join RealizacijaPlanDate t4 on t4.SAPSO = t1.DocNum and t4.Linija = t2.LineNum

WHERE  t0.U_BXPParWR is null and t0.U_BXPOrdTy = 'W' -- and  t0.U_BXPMTOSc =  'MTO_20250919102245'  -- 'MTO_20250812130414'
GROUP BY t0.U_BXPMTOSc ,t0.U_BXPWODcN, t2.ShipDate, t3.DatumSastavljanja, t4.PlanRealizacije

--order by   t0.U_BXPWODcN  ,  t0.U_BXPMTOSc , t2.ShipDate

)     



, glavninalog1 AS (
    SELECT
        MAX(t0.U_BXPWODcN) AS GlavniNalog,
        t0.U_BXPMTOSc     AS Scenario
    FROM [dbo].[@BXPMTOORDRSOLREF] t0
    WHERE t0.U_BXPParWR IS NULL
      AND t0.U_BXPOrdTy = 'W'
     -- AND t0.U_BXPMTOSc = N'MTO_20250919102245'
    GROUP BY t0.U_BXPMTOSc, t0.Code
)


, glavninalog2 as(

SELECT

    Scenario,
    STRING_AGG(CONVERT(varchar(20), GlavniNalog), ';') AS GlavniNalog
FROM glavninalog1
GROUP BY Scenario )


----Definiranje prvog datuma sastavljanja ukoliko nije kpl

, Datum_sastavljanja_min as (

select Scenario, min(DatumSastavljanja) 'DatumSastavljanja' 

from glavninalog group by Scenario

)



---Definiranje prvog datuma isporuke sa scenarija u slu?aju grupisanih naloga

,  Prvidatum (Datum,Narudžba,MTO)
as(

select min(t1.ShipDate) ,min(t0.DocNum) ,t2.U_BXPMTOSc
from ORDR t0 with (nolock)

inner join rdr1 t1 with (nolock) on t0.DocEntry = t1.DocEntry       
left join [@BXPMTOORDRSOLREF] t2 with (nolock) on t0.DocNum = t2.U_BXPSODcN and t2.U_BXPSOLin = t1.LineNum   

where t2.U_BXPParWR is null -- AND  T1.U_BXPMTOSc = 'MTO_20250919102245'
Group by t2.U_BXPMTOSc

)


SELECT  T0.PROJEKT, Prvidatum.Narudžba, case when CAST(t3.Glavninalog1 AS NVARCHAR (MAX)) is null then t5.GlavniNalog else CAST(t3.Glavninalog1 AS NVARCHAR (MAX)) end as  'Glavni nalog KPL', T0.RN, 

t0.Linija  'Linija', t2.ItemCode 


, T0.NazivProizvoda 

--,T4.Revizija

--replace ((cast (cast (t0.Ostalovremena  as decimal (15,2)) as  nvarchar)  +  'mins' )  ,  '.' , ',' )'Preostalo norme'


,

t0.Planiranokomadaponalogu ,

T0.Planiranokomadaponalogu - T0.Cekirano 'Ostalo Komada',


case when CAST(t3.ShipDate AS date) is null then cast(Prvidatum.Datum as date) else CAST(t3.ShipDate AS date)  end as  'Datum Isporuke',

case when CAST(t3.DatumSastavljanja AS date) is null then cast(t6.DatumSastavljanja as date) else CAST(t3.DatumSastavljanja AS date) end as  'DatumSastavljanja'

--,cast(Prvidatum.Datum as date) 'Datum Isporuke'

, cast (Baseqty as decimal (15,2)) 'Norma/kom'

, cast (T0.Planirano as decimal (15,2)) 'Planirana norma'

,cast (t0.Ostalovremena  as decimal (15,2)) 'Preostalo norme',



--CAST(t0.Naziv AS NVARCHAR (4000)) 'Naziv OP' 

t1.Name 'Naziv Masine'

--,CAST(t0.OPopis AS NVARCHAR(4000)) 'Opis OP'

--,null 'Kolona1',null 'Kolona2'

,t0.Mailstone    ,

case when CAST( t3.DatumPlanRealizacije AS date) is null then cast( t7.PlanRealizacije as date) else CAST(t3.DatumPlanRealizacije AS date)  end as  'Datum plan realizacije' , T0.mto


FROM #PREOSTALANORMA  T0   

INNER JOIN [dbo].[@BXPWORKCENTER] T1 with (nolock) ON t0.Masina = t1.Code  collate SQL_Latin1_General_CP1_CI_AS
INNER JOIN OWOR T2 with (nolock) ON T0.RN = T2.DocNum  


left join glavninalog t3 on t2.U_BXPMTOSc = t3.Scenario and t3.Glavninalog1 = t2.DocNum
left join Prvidatum on prvidatum.MTO =  t0.MTO collate SQL_Latin1_General_CP1_CI_AS
left join glavninalog2 t5 on t5.Scenario = t2.U_BXPMTOSc   
left join Datum_sastavljanja_min t6 on t6.Scenario = t2.U_BXPMTOSc 
LEFT join RealizacijaPlanDateGroup t7 on t7.U_BXPMTOSc = t2.U_BXPMTOSc 

where t1.Name not like '%kontrola%'


group by    Prvidatum.Narudžba ,t3.Glavninalog1,T0.RN, T0.NazivProizvoda, t2.ItemCode,t1.Name,T0.Ostalovremena ,t0.Linija,t0.Naziv ,t0.OPopis,t0.Planiranokomadaponalogu,T0.Cekirano,Prvidatum.Datum,T0.PROJEKT,t0.Masina,t5.GlavniNalog ,t3.ShipDate,t0.Mailstone,t3.DatumSastavljanja,t6.DatumSastavljanja  , t3.DatumPlanRealizacije, T0.mto,


t0.Planiranokomadaponalogu ,t7.PlanRealizacije,T0.Planirano, T0.Baseqty


order by  RN, LINIJA --t3.glavninalog1 ,t0.Masina, Prvidatum.Datum 


drop table #Open_MTO
drop table #PREOSTALANORMA
drop table #Projekt