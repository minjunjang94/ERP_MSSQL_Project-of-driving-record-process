IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'minjun_SACBusinessCarDailyUseCheck' AND xtype = 'P')    
    DROP PROC minjun_SACBusinessCarDailyUseCheck
GO
    
/*************************************************************************************************    
 설  명 - SP-운행기록부체크_minjun
 작성일 - '2020-04-01
 작성자 - 장민준
 수정자 - 
*************************************************************************************************/    
CREATE PROCEDURE dbo.minjun_SACBusinessCarDailyUseCheck
    @ServiceSeq    INT          = 0 ,   -- 서비스 내부코드
    @WorkingTag    NVARCHAR(10) = '',   -- WorkingTag
    @CompanySeq    INT          = 1 ,   -- 법인 내부코드
    @LanguageSeq   INT          = 1 ,   -- 언어 내부코드
    @UserSeq       INT          = 0 ,   -- 사용자 내부코드
    @PgmSeq        INT          = 0 ,   -- 프로그램 내부코드
    @IsTransaction BIT          = 0     -- 트랜젝션 여부
AS
    DECLARE @MessageType    INT             -- 오류메시지 타입
           ,@Status         INT             -- 상태변수
           ,@Results        NVARCHAR(250)   -- 결과문구
           ,@Count          INT             -- 채번데이터 Row 수
           ,@Seq            INT             -- Seq
           ,@MaxNo          NVARCHAR(20)    -- 채번 데이터 최대 No
           ,@Date           NCHAR(8)        -- Date
           ,@TblName        NVARCHAR(MAX)   -- Table명
           ,@SeqName        NVARCHAR(MAX)   -- Table 키값 명
    
    -- 테이블, 키값 명칭
    SELECT  @TblName    = N'minjun_TACCarDriveRecord'
           ,@SeqName    = N'CarSeq'
    






  -- 체크구문

---동일 날짜에 중복 순서 중복 체크
EXEC dbo._SCOMMessage   @MessageType    OUTPUT
                           ,@Status         OUTPUT
                           ,@Results        OUTPUT
                           ,6                       -- SELECT * FROM _TCAMessageLanguage WITH(NOLOCK) WHERE LanguageSeq = 1 AND Message LIKE '%가%입력%'
                           ,@LanguageSeq
                           ,0, '순'               -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
                           ,0, '번'                   -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
    UPDATE  #BIZ_OUT_DataBlock1
       SET  Result          = REPLACE(@Results, '@2', M.CarSeq)
           ,MessageType     = @MessageType
           ,Status          = @Status
      FROM  #BIZ_OUT_DataBlock1     AS M
            JOIN(   SELECT  *
                      FROM  minjun_TACCarDriveRecord         AS X   WITH(NOLOCK)
                     WHERE  X.CompanySeq    = @CompanySeq
                       AND  NOT EXISTS( SELECT  1
                                          FROM  #BIZ_OUT_DataBlock1
                                         WHERE  WorkingTag IN('U', 'D')
                                           AND  Status = 0
                                           AND  CarSeq     = X.CarSeq
                                           AND  CarSerl    = X.CarSerl
                                           )
                 )AS A    ON  A.CarSeq  = M.CarSeq
     WHERE  M.WorkingTag IN('A', 'U')
       AND  M.Status = 0
       AND  M.CarDate = A.CarDate
       AND  M.OrderSeq = A.OrderSeq





---주행전 < 주행 후 기록이 큰지 체크
EXEC dbo._SCOMMessage   @MessageType    OUTPUT
                           ,@Status         OUTPUT
                           ,@Results        OUTPUT
                           ,1329                       -- SELECT * FROM _TCAMessageLanguage WITH(NOLOCK) WHERE LanguageSeq = 1 AND Message LIKE '%가%잘못%'
                           ,@LanguageSeq
                           ,0, '주행 후 기록'               -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
                           ,0, '주행 후 기록'                   -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
    UPDATE  #BIZ_OUT_DataBlock1
       SET  Result          = REPLACE(@Results, '@2', M.CarSeq)
           ,MessageType     = @MessageType
           ,Status          = @Status
      FROM  #BIZ_OUT_DataBlock1     AS M
     WHERE  M.WorkingTag IN('A', 'U')
       AND  M.Status = 0
       AND  M.BeforeKm >= M.AfterKm



     -- - 등록자만 수정 및 삭제가 가능하도록
     EXEC dbo._SCOMMessage   @MessageType    OUTPUT
                            ,@Status         OUTPUT
                            ,@Results        OUTPUT
                            ,9                      -- SELECT * FROM _TCAMessageLanguage WITH(NOLOCK) WHERE LanguageSeq = 1 AND Message LIKE '%삭제%'
                            ,@LanguageSeq
                            ,0, '등록자'                   -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
                                                --SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
     UPDATE  #BIZ_OUT_DataBlock1
        SET  Result          = @Results
            ,MessageType     = @MessageType
            ,Status          = @Status
       FROM  #BIZ_OUT_DataBlock1     AS M
       JOIN (SELECT * FROM minjun_TACCarDriveRecord) AS A ON A.CompanySeq = @CompanySeq
                                                      AND A.CarSeq     = M.CarSeq
                                                      AND A.CarSerl    = M.CarSerl
      WHERE  M.WorkingTag IN('D','U')
        AND  M.Status = 0
        AND  @UserSeq <> A.LastUserSeq
  





-- 주행 전 후에 대해 중복된 KM입력시 체크  
    SELECT X.CarSeq,X.BeforeKm,X.AfterKm
      INTO #CarCheck  
      FROM #BIZ_OUT_DataBlock1 AS X  
     WHERE X.WorkingTag IN ('A','U')

     UNION ALL
	
    SELECT X.CarSeq,X.BeforeKm,X.AfterKm
      FROM minjun_TACCarDriveRecord AS X
     WHERE X.CompanySeq = @CompanySeq
       AND NOT EXISTS (SELECT *  
                         FROM #BIZ_OUT_DataBlock1  
                        WHERE WorkingTag IN ('A', 'U', 'D')  
                          AND CarSeq      = X.CarSeq
                          AND CarSerl     = X.CarSerl
                      )


    UPDATE #BIZ_OUT_DataBlock1
       SET Result      = '주행 전 후에 대해 중복된 KM입력되었습니다.',
           MessageType = 9999,
           Status      = 9999
      FROM #BIZ_OUT_DataBlock1 AS A
     WHERE EXISTS (SELECT *
                     FROM #CarCheck AS X
                    WHERE EXISTS (SELECT *
                                    FROM #CarCheck
                                   WHERE CarSeq  = X.CarSeq
                                     AND X.AfterKm  > BeforeKm
									 AND X.AfterKm < AfterKm
                                     AND AfterKm <> X.AfterKm
                                 ) 
                       AND X.CarSeq  = A.CarSeq
                )
       AND A.Status = 0


    UPDATE #BIZ_OUT_DataBlock1
       SET Result      = '주행 전 후에 대해 중복된 KM입력되었습니다.',
           MessageType = 9999,
           Status      = 9999
      FROM #BIZ_OUT_DataBlock1 AS A
     WHERE EXISTS (SELECT *
                     FROM #CarCheck AS X
                    WHERE X.CarSeq  = A.CarSeq
                 GROUP BY X.CarSeq, X.AfterKm
                   HAVING COUNT(*) > 1
                  )
       AND A.Status = 0


------ 체크구문 (중복된 KM)
--    EXEC dbo._SCOMMessage   @MessageType    OUTPUT
--                           ,@Status         OUTPUT
--                           ,@Results        OUTPUT
--                           ,1196                       -- SELECT * FROM _TCAMessageLanguage WITH(NOLOCK) WHERE LanguageSeq = 1 AND Message LIKE '%확인%'
--                           ,@LanguageSeq
--                           ,0, '계기판거리'                   -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
--                           ,0, ''                   -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
--    UPDATE  #BIZ_OUT_DataBlock1
--       SET  Result          = @Results
--           ,MessageType     = @MessageType
--           ,Status          = @Status
--    FROM  (SELECT  Z.BeforeKm, Z.AfterKm
--                      FROM (SELECT  X.CarSeq, X.CarSerl
--                                   ,X.BeforeKm, X.AfterKm
--                              FROM  minjun_TACCarDriveRecord         AS X   WITH(NOLOCK)
--                             WHERE  X.CompanySeq    = @CompanySeq
--                               AND  NOT EXISTS( SELECT  1
--                                                  FROM  #BIZ_OUT_DataBlock1
--                                                 WHERE  WorkingTag IN('U', 'D')
--                                                   AND  Status = 0
--                                                   AND  CarSeq     = X.CarSeq
--                                                   AND  CarSerl    = X.CarSerl)
--                            UNION ALL
--                            SELECT  Y.CarSeq, Y.CarSerl
--                                   ,Y.BeforeKm, Y.AfterKm
--                              FROM  #BIZ_OUT_DataBlock1         AS Y   WITH(NOLOCK)
--                             WHERE  Y.WorkingTag IN('A', 'U')
--                               AND  Y.Status = 0      )AS Z
--                     GROUP BY Z.BeforeKm, Z.AfterKm
--                     HAVING COUNT(1) > 1) AS M
--            JOIN(   SELECT  Z.BeforeKm, Z.AfterKm
--                      FROM (SELECT  X.CarSeq, X.CarSerl
--                                   ,X.BeforeKm, X.AfterKm
--                              FROM  minjun_TACCarDriveRecord         AS X   WITH(NOLOCK)
--                             WHERE  X.CompanySeq    = @CompanySeq
--                               AND  NOT EXISTS( SELECT  1
--                                                  FROM  #BIZ_OUT_DataBlock1
--                                                 WHERE  WorkingTag IN('U', 'D')
--                                                   AND  Status = 0
--                                                   AND  CarSeq     = X.CarSeq
--                                                   AND  CarSerl    = X.CarSerl)
--                            UNION ALL
--                            SELECT   Y.CarSeq, Y.CarSerl
--                                   ,Y.BeforeKm, Y.AfterKm
--                              FROM  #BIZ_OUT_DataBlock1         AS Y   WITH(NOLOCK)
--                             WHERE  Y.WorkingTag IN('A', 'U')
--                               AND  Y.Status = 0      )AS Z
--                     GROUP BY Z.BeforeKm, Z.AfterKm
--                     HAVING COUNT(1) > 1) AS A    ON  M.BeforeKm BETWEEN A.BeforeKm AND A.AfterKm-1  
--                                                       OR M.AfterKm  BETWEEN A.BeforeKm AND A.AfterKm 
--                                                       OR M.BeforeKm < A.BeforeKm AND M.AfterKm > A.AfterKm 
--     WHERE  M.WorkingTag IN('A', 'U')
--       AND  M.Status = 0















    -- 채번해야 하는 데이터 수 확인

    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 
     
    -- 채번
    IF @Count > 0
    BEGIN
        -- 내부코드채번 : 테이블별로 시스템에서 Max값으로 자동 채번된 값을 리턴하여 채번
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, @TblName, @SeqName, @Count
        

        UPDATE  #BIZ_OUT_DataBlock1
           SET  CarSerl = @Seq + DataSeq
         WHERE  WorkingTag  = 'A'
           AND  Status      = 0
        
      --  -- 외부번호 채번에 쓰일 일자값
      --  SELECT @Date = CONVERT(NVARCHAR(8), GETDATE(), 112)        
      --  
      --  -- 외부번호채번 : 업무별 외부키생성정의등록 화면에서 정의된 채번규칙으로 채번
      --  EXEC dbo._SCOMCreateNo 'SL', @TblName, @CompanySeq, '', @Date, @MaxNo OUTPUT
      --  
      --  UPDATE  #BIZ_OUT_DataBlock1
      --     SET  CarSerl = @MaxNo
      --   WHERE  WorkingTag  = 'A'
      --     AND  Status      = 0
    END

RETURN