IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'minjun_SACBusinessCarDailyUseSave' AND xtype = 'P')    
    DROP PROC minjun_SACBusinessCarDailyUseSave
GO
    
/*************************************************************************************************    
 ��  �� - SP-�����Ϻ�����_minjun
 �ۼ��� - '2020-04-01
 �ۼ��� - �����
 ������ - 
*************************************************************************************************/    
CREATE PROCEDURE dbo.minjun_SACBusinessCarDailyUseSave
    @ServiceSeq    INT          = 0 ,   -- ���� �����ڵ�
    @WorkingTag    NVARCHAR(10) = '',   -- WorkingTag
    @CompanySeq    INT          = 1 ,   -- ���� �����ڵ�
    @LanguageSeq   INT          = 1 ,   -- ��� �����ڵ�
    @UserSeq       INT          = 0 ,   -- ����� �����ڵ�
    @PgmSeq        INT          = 0 ,   -- ���α׷� �����ڵ�
    @IsTransaction BIT          = 0     -- Ʈ������ ����
AS
    DECLARE @TblName        NVARCHAR(MAX)   -- Table��
           ,@ItemTblName    NVARCHAR(MAX)   -- ��Table��
           ,@SeqName        NVARCHAR(MAX)   -- Seq��
           ,@SerlName       NVARCHAR(MAX)   -- Serl��
           ,@SQL            NVARCHAR(MAX)
           ,@TblColumns     NVARCHAR(MAX)
           ,@Seq            INT
    
    -- ���̺�, Ű�� ��Ī
    SELECT  @TblName        = N'minjun_TACCarDriveRecord'
           ,@ItemTblName    = N'minjun_TACCarDriveRecord'
           ,@SeqName        = N'CarSeq'
           ,@SerlName       = N'CarSerl'

    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  	
	SELECT @TblColumns = dbo._FGetColumnsForLog(@TblName)
    
    EXEC _SCOMLog @CompanySeq
                 ,@UserSeq   
                 ,@TblName                  -- ���̺��      
                 ,'#BIZ_OUT_DataBlock1'     -- �ӽ� ���̺��      
                 ,@SeqName                  -- CompanySeq�� ������ Ű(Ű�� �������� ���� , �� ���� )      
                 ,@TblColumns               -- ���̺� ��� �ʵ��
                 ,''
                 ,@PgmSeq
                    
    -- =============================================================================================================================================
    -- DELETE
    -- =============================================================================================================================================
    IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN
        -- Detail���̺� �����α� �����
        SELECT  @ItemTblName    = @TblName + N'Item'

        -- Detail���̺� �÷��� ��������
        SELECT  @TblColumns     = dbo._FGetColumnsForLog(@ItemTblName)

        -- Query �������� ���
        SELECT  @SQL    = N''
        SELECT  @SQL    = N'
        INSERT INTO '+@ItemTblName+N'Log('+
            @TblColumns + N'
           ,LogUserSeq
           ,LogDateTime
           ,LogType 
           ,LogPgmSeq
        )
        SELECT  '+@TblColumns+N'
               ,CONVERT(INT, '+CONVERT(NVARCHAR, @UserSeq)+N')
               ,GETDATE()
               ,''D''
               ,CONVERT(INT, '+CONVERT(NVARCHAR, @PgmSeq)+N')
          FROM  '+@ItemTblName+N'  WITH(NOLOCK)
         WHERE  CompanySeq = CONVERT(INT, '+CONVERT(NVARCHAR, @CompanySeq)+')
           AND  '+@SeqName+N' = CONVERT(INT, '+CONVERT(NVARCHAR, @Seq)+')'
        
        -- Query ����
        EXEC SP_EXECUTESQL @SQL

        IF @@ERROR <> 0 RETURN

        -- Detail���̺� ������ ����
        DELETE  A
          FROM  #BIZ_OUT_DataBlock1                            AS M
                JOIN minjun_TACCarDriveRecord                  AS A  WITH(NOLOCK)  ON  A.CompanySeq    = @CompanySeq
                                                               AND  A.CarSeq      = M.CarSeq
         WHERE  M.WorkingTag    = 'D'
           AND  M.Status        = 0

        IF @@ERROR <> 0 RETURN
        
 --       -- Master���̺� ������ ����
 --       DELETE  A
 --         FROM  #BIZ_OUT_DataBlock1         AS M
 --               JOIN minjun_TACCarDriveRecord              AS A  WITH(NOLOCK)  ON  A.CompanySeq    = @CompanySeq
 --                                                              AND  A.CarSeq      = M.CarSeq
 --        WHERE  M.WorkingTag    = 'D'
 --          AND  M.Status        = 0
 --   
 --       IF @@ERROR <> 0 RETURN
    END

    -- =============================================================================================================================================
    -- Update
    -- =============================================================================================================================================
    IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN
        UPDATE  A 
           SET                       
                     DeptSeq                    = M.DeptSeq           
                    ,CarSerl                    = M.CarSerl 
                    ,EmpSeq                     = M.EmpSeq             
                    ,UMDriveKind                = M.UMDriveKind        
                    ,UMStartGroup               = M.UMStartGroup       
                    ,UMArriveGroup              = M.UMArriveGroup              
                    ,CarDate                    = M.CarDate            
                    ,OrderSeq                   = M.OrderSeq                 
                    ,StartPlace                 = M.StartPlace         
                    ,StartAddr                  = M.StartAddr          
                    ,ArrivePlace                = M.ArrivePlace        
                    ,ArriveAddr                 = M.ArriveAddr         
                    ,BeforeKm                   = M.BeforeKm           
                    ,AfterKm                    = M.AfterKm            
                    --,KM                         = M.KM                 
                    ,WorkKm                     = M.WorkKm             
                    ,Remark                     = M.Remark          
                    ,LastUserSeq                = @UserSeq
                    ,LastDateTime               = GETDATE()
        


          FROM  #BIZ_OUT_DataBlock1         AS M
                JOIN minjun_TACCarDriveRecord              AS A  WITH(NOLOCK)  ON   A.CompanySeq    = @CompanySeq
                                                                               AND  A.CarSeq        = M.CarSeq
         WHERE  M.WorkingTag    = 'U'
           AND  M.Status        = 0

        IF @@ERROR <> 0 RETURN
    END

    -- =============================================================================================================================================
    -- INSERT
    -- =============================================================================================================================================
    IF EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN
        INSERT INTO minjun_TACCarDriveRecord (

          CompanySeq
         ,CarSeq
         ,CarSerl          
         ,DeptSeq          
         ,EmpSeq           
         ,UMDriveKind      
         ,UMStartGroup     
         ,UMArriveGroup          
         ,CarDate          
         ,OrderSeq         
         ,StartPlace       
         ,StartAddr        
         ,ArrivePlace      
         ,ArriveAddr       
         ,BeforeKm         
         ,AfterKm          
         --,KM             
         ,WorkKm           
         ,Remark           
         ,LastUserSeq 
         ,LastDateTime

        )
        SELECT  
         @CompanySeq
        ,M.CarSeq
        ,M.CarSerl          
        ,M.DeptSeq          
        ,M.EmpSeq           
        ,M.UMDriveKind      
        ,M.UMStartGroup     
        ,M.UMArriveGroup              
        ,M.CarDate          
        ,M.OrderSeq         
        ,M.StartPlace       
        ,M.StartAddr        
        ,M.ArrivePlace      
        ,M.ArriveAddr       
        ,M.BeforeKm         
        ,M.AfterKm          
        --,M.KM             
        ,M.WorkKm           
        ,M.Remark           
        ,@UserSeq
        ,GETDATE()

          FROM  #BIZ_OUT_DataBlock1         AS M
         WHERE  M.WorkingTag    = 'A'
           AND  M.Status        = 0

        IF @@ERROR <> 0 RETURN
    END

RETURN