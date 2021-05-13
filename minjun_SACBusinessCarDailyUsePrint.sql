IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID('minjun_SACBusinessCarDailyUsePrint') AND sysstat & 0xf = 4) /*★*/
    DROP PROCEDURE dbo.minjun_SACBusinessCarDailyUsePrint /*★*/
GO

CREATE PROCEDURE minjun_SACBusinessCarDailyUsePrint /*★*/    
    @ServiceSeq    INT          = 0 ,  
    @WorkingTag    NVARCHAR(10) = '',  
    @CompanySeq    INT          = 1 ,  
    @LanguageSeq   INT          = 1 ,  
    @UserSeq       INT          = 0 ,  
    @PgmSeq        INT          = 0 ,  
    @IsTransaction BIT          = 0 
AS  
  
    -- 하기 SELECT 구문에 대해 필요에 따라 로직을 수정하여 조회합니다.  

    DECLARE 

     @YYMM                   NCHAR(6)          
    ,@YYMMTo                 NCHAR(6)          
    ,@CarSeq                 INT               
    ,@DateSumKm              decimal(19,5)               
    ,@UseWorkKm              decimal(19,5)             
    ,@UseRate                decimal(19,5)               
    ,@BasicKM                INT               
    ,@ToTalSumKm             decimal(19,5)               
    ,@ToTalUseWorkKm         decimal(19,5)       
    ,@ToTalUseRate           decimal(19,5)              


    SELECT  
             @YYMM                      = RTRIM(LTRIM(ISNULL(M.YYMM              , '')))
            ,@YYMMTo                    = RTRIM(LTRIM(ISNULL(M.YYMMTo            , '')))
            ,@CarSeq                    = RTRIM(LTRIM(ISNULL(M.CarSeq            , 0 )))
            

      FROM  #BIZ_IN_DataBlock1      AS M

      

       -- 출력 버튼 클릭시 차량번호가 조회조건에 없을 시 에러 메시지 표현
       IF ISNULL(@CarSeq, 0) = 0
            BEGIN
               UPDATE #BIZ_IN_DataBlock1
                  SET Result      = '차량번호가 입력되지 않았습니다.',
                      Status      = 9999
                 FROM #BIZ_IN_DataBlock1 AS A 
                WHERE A.Status       = 0
                  AND A.WorkingTag IN ('A')
               SELECT * FROM #BIZ_IN_DataBlock1 RETURN
            END





      SET @DateSumKm            = (SELECT SUM(WorkKm) FROM minjun_TACCarDriveRecord WHERE LEFT(CarDate, 6) Between @YYMM and @YYMMTo)

      SET @UseWorkKm            = (SELECT SUM(WorkKm) FROM minjun_TACCarDriveRecord WHERE LEFT(CarDate, 6) BetWeen @YYMM and @YYMMTo AND UMDriveKind = 2000130001)

      SET @UseRate              = @UseWorkKm / @DateSumKm * 100

      SET @BasicKM              = (SELECT BasicKM FROM minjun_TACCarRegistration WHERE CarSeq = @CarSeq)

      SET @ToTalSumKm           = (@BasicKM + (SELECT SUM(WorkKm) FROM minjun_TACCarDriveRecord WHERE LEFT(CarDate, 6) <= @YYMMTo AND CarSeq = @CarSeq))

      SET @ToTalUseWorkKm       = (SELECT SUM(WorkKm) FROM minjun_TACCarDriveRecord WHERE LEFT(CarDate, 6) <= @YYMMTo AND UMDriveKind = 2000130001)

      SET @ToTalUseRate         = (@ToTalSumKm / @ToTalUseWorkKm) * 100




                                    
           --Master  
    SELECT   
            @YYMM                       AS   YYMM  
           ,@YYMMTo                     AS   YYMMTo
           ,C.CompanyName               AS   CompanyName          --회사이름
           ,A.CarNo                     AS   CarNo                --차량번호
           ,D.DeptName                  AS   DeptName             --부서
           ,E.EmpName                   AS   EmpName              --담당자
           ,@DateSumKm                  AS   DateSumKm            --조회기간에 집계된 WorkKm의 합
           ,@UseWorkKm                  AS   UseWorkKm            --조회기간에 집계된 구분이 업무용 데이터 WorkKm의 합
           ,@UseRate                    AS   UseRate              --업무용사용km / 총주행Km * 100
           ,A.BasicKM                   AS   BasicKM              --업무용차량등록의 기본 KM
           ,@ToTalSumKm                 AS   ToTalSumKm           --기초 KM +  해당 차량  과거 ~ YYMMTo 총 WorkKm의합
           ,@ToTalUseWorkKm             AS   ToTalUseWorkKm       --구분이 업무용인 데이터의  과거 ~ YYMMTo 총 WorkKm의합
           ,@ToTalUseRate               AS   ToTalUseRate         --업무용사용KM 합계 / 총주행KM 합계 * 100
           ,B.CarDate                   AS   CarDate              --운행일
           ,G.MinorName                 AS   UMDriveKindName      --구분
           ,B.StartPlace                AS   StartPlace           --출발지명
           ,B.StartAddr                 AS   StartAddr            --출발주소
           ,B.ArrivePlace               AS   ArrivePlace          --도착지명
           ,B.ArriveAddr                AS   ArriveAddr           --도착주소
           ,B.BeforeKm                  AS   BeforeKm             --주행전계기판거리(KM)
           ,B.AfterKm                   AS   AfterKm              --주행후계기판거리(KM)
           ,B.WorkKm                    AS   KM                   --업무용주행거리(KM)
           ,(select sum(WorkKm)             
             from minjun_TACCarDriveRecord    
             where UMDriveKind = 2000130002) AS NoWorkKm          --구분이 비 업무용일 때 WorkKm
           ,(select sum(WorkKm)             
             from minjun_TACCarDriveRecord    
             where UMDriveKind = 2000130001) AS WorkKm            --구분이 업무용일 때 WorkKm 
           ,B.Remark                    AS   Remark               --비고
           


          

      FROM minjun_TACCarRegistration                    AS A WITH(NOLOCK)

           JOIN minjun_TACCarDriveRecord                AS B WITH(NOLOCK)           ON  B.CompanySeq  = A.CompanySeq  
                                                                                    AND B.CarSeq      = A.CarSeq

           LEFT OUTER JOIN _TCACompany                  AS C WITH(NOLOCK)           ON  C.CompanySeq  = A.CompanySeq 

           LEFT OUTER JOIN _TDADept                     AS D WITH(NOLOCK)           ON  D.CompanySeq  = B.CompanySeq  
                                                                                    AND D.DeptSeq     = B.DeptSeq  

           LEFT OUTER JOIN _TDAEmp                      AS E WITH(NOLOCK)           ON  E.CompanySeq  = A.CompanySeq  
                                                                                    AND E.EmpSeq      = A.EmpSeq  

           LEFT OUTER JOIN _TACASST                     AS F WITH(NOLOCK)           ON  F.CompanySeq  = A.CompanySeq
                                                                                    AND F.AsstSeq     = A.AsstSeq

           LEFT OUTER JOIN _TDAUMinor                   AS G WITH(NOLOCK)           ON  G.CompanySeq  = B.CompanySeq
                                                                                    AND G.MinorSeq    = B.UMDriveKind


     WHERE A.CompanySeq = @CompanySeq  
      AND  LEFT(B.CarDate,6) BETWEEN @YYMM AND @YYMMTo  
      AND  A.CarSeq  = @CarSeq 
        
RETURN  

