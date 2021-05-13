IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'minjun_SACBusinessCarDailyUseQuery' AND xtype = 'P')    
    DROP PROC minjun_SACBusinessCarDailyUseQuery
GO
    
/*************************************************************************************************    
 설  명 - SP-운행기록부조회_minjun
 작성일 - '2020-04-01
 작성자 - 장민준
 수정자 - 
*************************************************************************************************/    
CREATE PROCEDURE dbo.minjun_SACBusinessCarDailyUseQuery
    @ServiceSeq    INT          = 0 ,   -- 서비스 내부코드
    @WorkingTag    NVARCHAR(10) = '',   -- WorkingTag
    @CompanySeq    INT          = 1 ,   -- 법인 내부코드
    @LanguageSeq   INT          = 1 ,   -- 언어 내부코드
    @UserSeq       INT          = 0 ,   -- 사용자 내부코드
    @PgmSeq        INT          = 0 ,   -- 프로그램 내부코드
    @IsTransaction BIT          = 0     -- 트랜젝션 여부
AS
    -- 변수선언
    DECLARE  
             @YYMM           NCHAR(6)  
            ,@YYMMTo         NCHAR(6)
            ,@CarSeq        INT
            ,@DeptSeq       INT
            ,@EmpSeq        INT

       

    -- 조회조건 받아오기
    SELECT  @YYMM        = RTRIM(LTRIM(ISNULL(M.YYMM       , '')))
           ,@YYMMTo      = RTRIM(LTRIM(ISNULL(M.YYMMTo     , '')))
           ,@CarSeq      = RTRIM(LTRIM(ISNULL(M.CarSeq     ,  0)))
           ,@DeptSeq     = RTRIM(LTRIM(ISNULL(M.DeptSeq    ,  0)))
           ,@EmpSeq      = RTRIM(LTRIM(ISNULL(M.EmpSeq     ,  0)))


      FROM  #BIZ_IN_DataBlock1      AS M



          IF @YYMM = ''   SET @YYMM = '19000101'
          IF @YYMMTo = '' SET @YYMMTo = '99991231'    

    -- 조회결과 담아주기
    SELECT  
                  A.CarSeq
                , B.CarNo
                , A.CarSerl
                , D.DeptSeq
                , C.EmpSeq
                , A.UMDriveKind
                , A.UMStartGroup
                , A.UMArriveGroup
                , A.CarSerl
                , A.CarDate
                , A.OrderSeq
                , D.DeptName
                , C.EmpName
                , M2.MajorSeq  AS UMDriveKindName
                , M0.MajorSeq  AS UMStartGroupName
                , A.StartPlace
                , A.StartAddr
                , M1.MajorSeq  AS UMArriveGroupName
                , A.ArrivePlace
                , A.ArriveAddr
                , A.BeforeKm
                , A.AfterKm
                , A.AfterKm - A.BeforeKm    AS KM
                , A.WorkKm
                , A.Remark

               


      FROM  minjun_TACCarDriveRecord                    AS A
            LEFT OUTER JOIN minjun_TACCarRegistration   AS B    WITH(NOLOCK)  ON  B.CompanySeq      = A.CompanySeq
                                                                              AND B.CarSeq          = A.CarSeq
            LEFT OUTER JOIN _TDAEmp                     AS C    WITH(NOLOCK)  ON  C.CompanySeq      = B.CompanySeq
                                                                              AND C.EmpSeq          = B.EmpSeq
            LEFT OUTER JOIN _TDADept                    AS D    WITH(NOLOCK)  ON  D.CompanySeq      = A.CompanySeq
                                                                              AND D.DeptSeq         = A.DeptSeq
            LEFT OUTER JOIN _TDAUMinor                  AS M0   WITH(NOLOCK)  ON  M0.CompanySeq     = A.CompanySeq
                                                                             AND  M0.MajorSeq       = A.UMStartGroup
            LEFT OUTER JOIN _TDAUMinor                  AS M1   WITH(NOLOCK)  ON  M1.CompanySeq     = A.CompanySeq
                                                                             AND  M1.MajorSeq       = A.UMArriveGroup
            LEFT OUTER JOIN _TDAUMinor                  AS M2   WITH(NOLOCK)  ON  M2.CompanySeq     = A.CompanySeq
                                                                             AND  M2.MajorSeq       = A.UMDriveKind


     WHERE  A.CompanySeq    = @CompanySeq
       AND  LEFT(A.CarDate,6)     BETWEEN @YYMM     And @YYMMTo  --원래는 8개 단위이지만 6개 단위로 바꿔줘야 인식된다.
       AND (@CarSeq                = 0                  OR  A.CarSeq           = @CarSeq                   )
       AND (@DeptSeq               = 0                  OR  D.DeptSeq          = @DeptSeq                  )
       AND (@EmpSeq                = 0                  OR  C.EmpSeq           = @EmpSeq                    )  


       
     Order By CarDate, CarSeq

RETURN

select * from minjun_TACCarDriveRecord