IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'minjun_SACBusinessCarDailyUseCheck' AND xtype = 'P')    
    DROP PROC minjun_SACBusinessCarDailyUseCheck
GO
    
/*************************************************************************************************    
 ��  �� - SP-�����Ϻ�üũ_minjun
 �ۼ��� - '2020-04-01
 �ۼ��� - �����
 ������ - 
*************************************************************************************************/    
CREATE PROCEDURE dbo.minjun_SACBusinessCarDailyUseCheck
    @ServiceSeq    INT          = 0 ,   -- ���� �����ڵ�
    @WorkingTag    NVARCHAR(10) = '',   -- WorkingTag
    @CompanySeq    INT          = 1 ,   -- ���� �����ڵ�
    @LanguageSeq   INT          = 1 ,   -- ��� �����ڵ�
    @UserSeq       INT          = 0 ,   -- ����� �����ڵ�
    @PgmSeq        INT          = 0 ,   -- ���α׷� �����ڵ�
    @IsTransaction BIT          = 0     -- Ʈ������ ����
AS
    DECLARE @MessageType    INT             -- �����޽��� Ÿ��
           ,@Status         INT             -- ���º���
           ,@Results        NVARCHAR(250)   -- �������
           ,@Count          INT             -- ä�������� Row ��
           ,@Seq            INT             -- Seq
           ,@MaxNo          NVARCHAR(20)    -- ä�� ������ �ִ� No
           ,@Date           NCHAR(8)        -- Date
           ,@TblName        NVARCHAR(MAX)   -- Table��
           ,@SeqName        NVARCHAR(MAX)   -- Table Ű�� ��
    
    -- ���̺�, Ű�� ��Ī
    SELECT  @TblName    = N'minjun_TACCarDriveRecord'
           ,@SeqName    = N'CarSeq'
    






  -- üũ����

---���� ��¥�� �ߺ� ���� �ߺ� üũ
EXEC dbo._SCOMMessage   @MessageType    OUTPUT
                           ,@Status         OUTPUT
                           ,@Results        OUTPUT
                           ,6                       -- SELECT * FROM _TCAMessageLanguage WITH(NOLOCK) WHERE LanguageSeq = 1 AND Message LIKE '%��%�Է�%'
                           ,@LanguageSeq
                           ,0, '��'               -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
                           ,0, '��'                   -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
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





---������ < ���� �� ����� ū�� üũ
EXEC dbo._SCOMMessage   @MessageType    OUTPUT
                           ,@Status         OUTPUT
                           ,@Results        OUTPUT
                           ,1329                       -- SELECT * FROM _TCAMessageLanguage WITH(NOLOCK) WHERE LanguageSeq = 1 AND Message LIKE '%��%�߸�%'
                           ,@LanguageSeq
                           ,0, '���� �� ���'               -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
                           ,0, '���� �� ���'                   -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
    UPDATE  #BIZ_OUT_DataBlock1
       SET  Result          = REPLACE(@Results, '@2', M.CarSeq)
           ,MessageType     = @MessageType
           ,Status          = @Status
      FROM  #BIZ_OUT_DataBlock1     AS M
     WHERE  M.WorkingTag IN('A', 'U')
       AND  M.Status = 0
       AND  M.BeforeKm >= M.AfterKm



     -- - ����ڸ� ���� �� ������ �����ϵ���
     EXEC dbo._SCOMMessage   @MessageType    OUTPUT
                            ,@Status         OUTPUT
                            ,@Results        OUTPUT
                            ,9                      -- SELECT * FROM _TCAMessageLanguage WITH(NOLOCK) WHERE LanguageSeq = 1 AND Message LIKE '%����%'
                            ,@LanguageSeq
                            ,0, '�����'                   -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
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
  





-- ���� �� �Ŀ� ���� �ߺ��� KM�Է½� üũ  
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
       SET Result      = '���� �� �Ŀ� ���� �ߺ��� KM�ԷµǾ����ϴ�.',
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
       SET Result      = '���� �� �Ŀ� ���� �ߺ��� KM�ԷµǾ����ϴ�.',
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


------ üũ���� (�ߺ��� KM)
--    EXEC dbo._SCOMMessage   @MessageType    OUTPUT
--                           ,@Status         OUTPUT
--                           ,@Results        OUTPUT
--                           ,1196                       -- SELECT * FROM _TCAMessageLanguage WITH(NOLOCK) WHERE LanguageSeq = 1 AND Message LIKE '%Ȯ��%'
--                           ,@LanguageSeq
--                           ,0, '����ǰŸ�'                   -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = 1 AND Word LIKE '%%'
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















    -- ä���ؾ� �ϴ� ������ �� Ȯ��

    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 
     
    -- ä��
    IF @Count > 0
    BEGIN
        -- �����ڵ�ä�� : ���̺��� �ý��ۿ��� Max������ �ڵ� ä���� ���� �����Ͽ� ä��
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, @TblName, @SeqName, @Count
        

        UPDATE  #BIZ_OUT_DataBlock1
           SET  CarSerl = @Seq + DataSeq
         WHERE  WorkingTag  = 'A'
           AND  Status      = 0
        
      --  -- �ܺι�ȣ ä���� ���� ���ڰ�
      --  SELECT @Date = CONVERT(NVARCHAR(8), GETDATE(), 112)        
      --  
      --  -- �ܺι�ȣä�� : ������ �ܺ�Ű�������ǵ�� ȭ�鿡�� ���ǵ� ä����Ģ���� ä��
      --  EXEC dbo._SCOMCreateNo 'SL', @TblName, @CompanySeq, '', @Date, @MaxNo OUTPUT
      --  
      --  UPDATE  #BIZ_OUT_DataBlock1
      --     SET  CarSerl = @MaxNo
      --   WHERE  WorkingTag  = 'A'
      --     AND  Status      = 0
    END

RETURN