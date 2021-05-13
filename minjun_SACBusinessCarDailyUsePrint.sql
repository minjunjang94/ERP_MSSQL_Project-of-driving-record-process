IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID('minjun_SACBusinessCarDailyUsePrint') AND sysstat & 0xf = 4) /*��*/
    DROP PROCEDURE dbo.minjun_SACBusinessCarDailyUsePrint /*��*/
GO

CREATE PROCEDURE minjun_SACBusinessCarDailyUsePrint /*��*/    
    @ServiceSeq    INT          = 0 ,  
    @WorkingTag    NVARCHAR(10) = '',  
    @CompanySeq    INT          = 1 ,  
    @LanguageSeq   INT          = 1 ,  
    @UserSeq       INT          = 0 ,  
    @PgmSeq        INT          = 0 ,  
    @IsTransaction BIT          = 0 
AS  
  
    -- �ϱ� SELECT ������ ���� �ʿ信 ���� ������ �����Ͽ� ��ȸ�մϴ�.  

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

      

       -- ��� ��ư Ŭ���� ������ȣ�� ��ȸ���ǿ� ���� �� ���� �޽��� ǥ��
       IF ISNULL(@CarSeq, 0) = 0
            BEGIN
               UPDATE #BIZ_IN_DataBlock1
                  SET Result      = '������ȣ�� �Էµ��� �ʾҽ��ϴ�.',
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
           ,C.CompanyName               AS   CompanyName          --ȸ���̸�
           ,A.CarNo                     AS   CarNo                --������ȣ
           ,D.DeptName                  AS   DeptName             --�μ�
           ,E.EmpName                   AS   EmpName              --�����
           ,@DateSumKm                  AS   DateSumKm            --��ȸ�Ⱓ�� ����� WorkKm�� ��
           ,@UseWorkKm                  AS   UseWorkKm            --��ȸ�Ⱓ�� ����� ������ ������ ������ WorkKm�� ��
           ,@UseRate                    AS   UseRate              --��������km / ������Km * 100
           ,A.BasicKM                   AS   BasicKM              --��������������� �⺻ KM
           ,@ToTalSumKm                 AS   ToTalSumKm           --���� KM +  �ش� ����  ���� ~ YYMMTo �� WorkKm����
           ,@ToTalUseWorkKm             AS   ToTalUseWorkKm       --������ �������� ��������  ���� ~ YYMMTo �� WorkKm����
           ,@ToTalUseRate               AS   ToTalUseRate         --��������KM �հ� / ������KM �հ� * 100
           ,B.CarDate                   AS   CarDate              --������
           ,G.MinorName                 AS   UMDriveKindName      --����
           ,B.StartPlace                AS   StartPlace           --�������
           ,B.StartAddr                 AS   StartAddr            --����ּ�
           ,B.ArrivePlace               AS   ArrivePlace          --��������
           ,B.ArriveAddr                AS   ArriveAddr           --�����ּ�
           ,B.BeforeKm                  AS   BeforeKm             --����������ǰŸ�(KM)
           ,B.AfterKm                   AS   AfterKm              --�����İ���ǰŸ�(KM)
           ,B.WorkKm                    AS   KM                   --����������Ÿ�(KM)
           ,(select sum(WorkKm)             
             from minjun_TACCarDriveRecord    
             where UMDriveKind = 2000130002) AS NoWorkKm          --������ �� �������� �� WorkKm
           ,(select sum(WorkKm)             
             from minjun_TACCarDriveRecord    
             where UMDriveKind = 2000130001) AS WorkKm            --������ �������� �� WorkKm 
           ,B.Remark                    AS   Remark               --���
           


          

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

