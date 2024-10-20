USE [DBContacts]
GO

IF OBJECT_ID('dbo.SearchContacts', 'P') IS NOT NULL
DROP PROCEDURE dbo.SearchContacts;
GO
IF OBJECT_ID('dbo.ExportContactsToCsv', 'P') IS NOT NULL
DROP PROCEDURE dbo.ExportContactsToCsv
GO
IF(OBJECT_ID('dbo.GetCompanyProfileByCompanyId', 'P')) IS NOT NULL
DROP PROCEDURE dbO.GetCompanyProfileByCompanyId
GO
IF(OBJECT_ID('dbo.GetRelatedCompanies', 'P')) IS NOT NULL
DROP PROCEDURE dbo.GetRelatedCompanies
GO

IF EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'ContactFilterType' AND SCHEMA_NAME(schema_id) = 'dbo')
BEGIN
    DROP TYPE [dbo].[ContactFilterType];
END;
GO
IF EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'StringList' AND SCHEMA_NAME(schema_id) = 'dbo')
BEGIN
    DROP TYPE [dbo].[StringList];
END;
GO
CREATE TYPE [dbo].[StringList] AS TABLE(
	[Value] [nvarchar](500) NULL
)
GO
CREATE TYPE [dbo].[ContactFilterType] AS TABLE(
	[Value] [int] NULL
)
GO
CREATE PROCEDURE [dbo].[GetRelatedCompanies]
    @CompanyId INT,
    @ProductServices dbo.StringList READONLY
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #ValidCompanies (CompanyId INT PRIMARY KEY);
    INSERT INTO #ValidCompanies (CompanyId)
    SELECT DISTINCT TOP 50 c.Id
    FROM Companies c
    WHERE c.Id <> @CompanyId
      AND EXISTS (
          SELECT 1
          FROM @ProductServices ps
          WHERE c.CompanyProductsServices LIKE '%' + LTRIM(RTRIM(ps.Value)) + '%' -- Avoid leading %
      );

    IF EXISTS (SELECT 1 FROM #ValidCompanies)
    BEGIN
        SELECT TOP 4 
            c.Id AS CompanyId, 
            c.CompanyName, 
        CASE 
            WHEN c.CompanyProfileImageUrl IS NULL OR c.CompanyProfileImageUrl = '' THEN NULL 
            WHEN LEFT(c.CompanyProfileImageUrl, 4) <> 'http' THEN 'https://' + c.CompanyProfileImageUrl 
            ELSE c.CompanyProfileImageUrl 
        END AS CompanyProfileImageUrl
        FROM Companies c
        INNER JOIN #ValidCompanies vc ON c.Id = vc.CompanyId
        ORDER BY RAND();
    END

    DROP TABLE #ValidCompanies;
END;

Go
CREATE PROCEDURE [dbo].[SearchContacts]    
    @CompanyName NVARCHAR(255) = NULL,  
    @CompanySize dbo.ContactFilterType READONLY,  
    @Name NVARCHAR(255) = NULL,    
    @Email NVARCHAR(255) = NULL,   
    @EmailScore dbo.ContactFilterType READONLY,   
    @LeadLocation NVARCHAR(255) = NULL,   
    @LeadDivision dbo.ContactFilterType READONLY,    
    @SeniorityLevel dbo.ContactFilterType READONLY,   
    @CompanySector NVARCHAR(255) = NULL,   
    @RevenueRange dbo.ContactFilterType READONLY,    
    @CompanyIndustry dbo.ContactFilterType READONLY,  
    @LeadTitle NVARCHAR(255) = NULL,  
    @CompanyNAICSCode INT = NULL,    
    @CompanySICCode INT = NULL,   
    @Keyword NVARCHAR(255) = NULL,  
    @PageNumber INT = 1,    
    @PageSize INT = 25    
AS    
BEGIN    
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @WhereClauseContacts NVARCHAR(MAX) = '1=1'; -- Contacts filtering
    DECLARE @WhereClauseCompanies NVARCHAR(MAX) = '1=1'; -- Companies filtering

    -- Step 1: Filter conditions for Contacts table
    IF @Name IS NOT NULL AND @Name != ''
        SET @WhereClauseContacts = @WhereClauseContacts + ' AND c.Name LIKE ''%' + @Name + '%''';
    IF @Email IS NOT NULL AND @Email !=''
        SET @WhereClauseContacts = @WhereClauseContacts + ' AND c.Email LIKE ''%' + @Email + '%''';
    IF @LeadTitle IS NOT NULL AND @LeadTitle !=''
        SET @WhereClauseContacts = @WhereClauseContacts + ' AND c.LeadTitle LIKE ''%' + @LeadTitle + '%''';
    IF @LeadLocation IS NOT NULL AND @LeadLocation !=''
        SET @WhereClauseContacts = @WhereClauseContacts + ' AND c.LeadLocationID IN (SELECT l.Id FROM LeadLocations l WHERE l.Location LIKE ''%' + @LeadLocation + '%'')';
    IF EXISTS (SELECT 1 FROM @LeadDivision)
        SET @WhereClauseContacts = @WhereClauseContacts + ' AND c.LeadDivisionID IN (SELECT Value FROM @LeadDivision)';
    IF EXISTS (SELECT 1 FROM @SeniorityLevel)
        SET @WhereClauseContacts = @WhereClauseContacts + ' AND c.SeniorityLevelID IN (SELECT Value FROM @SeniorityLevel)';
    IF EXISTS (SELECT 1 FROM @EmailScore)
        SET @WhereClauseContacts = @WhereClauseContacts + ' AND c.EmailScore IN (SELECT Value FROM @EmailScore)';

    -- Step 2: Filter conditions for Companies table (separate conditions)
    IF @CompanyName IS NOT NULL AND @CompanyName != ''
        SET @WhereClauseCompanies = @WhereClauseCompanies + ' AND co.CompanyName LIKE ''%' + @CompanyName + '%''';
    IF @Keyword IS NOT NULL AND @Keyword != ''
        SET @WhereClauseCompanies = @WhereClauseCompanies + ' AND co.keywords LIKE ''%' + @Keyword + '%''';
    IF EXISTS (SELECT 1 FROM @CompanyIndustry)
        SET @WhereClauseCompanies = @WhereClauseCompanies + ' AND co.CompanyIndustryID IN (SELECT Value FROM @CompanyIndustry)';
    IF EXISTS (SELECT 1 FROM @CompanySize)
        SET @WhereClauseCompanies = @WhereClauseCompanies + ' AND co.CompanySizeID IN (SELECT Value FROM @CompanySize)';
    IF EXISTS (SELECT 1 FROM @RevenueRange)
        SET @WhereClauseCompanies = @WhereClauseCompanies + ' AND co.RevenueRange IN (SELECT Value FROM @RevenueRange)';
    IF @CompanySector IS NOT NULL AND @CompanySector != ''
        SET @WhereClauseCompanies = @WhereClauseCompanies + ' AND co.CompanySectorId IN (SELECT s.Id FROM CompanySectors s WHERE s.CompanySector LIKE ''%' + @CompanySector + '%'')';
    IF @CompanyNAICSCode IS NOT NULL
        SET @WhereClauseCompanies = @WhereClauseCompanies + ' AND co.CompanyNAICSCode = @CompanyNAICSCode';
    IF @CompanySICCode IS NOT NULL
        SET @WhereClauseCompanies = @WhereClauseCompanies + ' AND co.CompanySICCode = @CompanySICCode';

    -- Step 3: Build the main query
    SET @SQL = '
    WITH FilteredContacts AS (
        SELECT c.CompanyID
        FROM Contacts c WITH(NOLOCK)
        WHERE ' + @WhereClauseContacts + '
    )
    SELECT COUNT_BIG(1) AS RecordsFiltered
    FROM FilteredContacts fc
    INNER JOIN Companies co WITH(NOLOCK) ON fc.CompanyID = co.Id
    WHERE ' + @WhereClauseCompanies + ';

    SELECT RecordsTotal FROM dbo.vw_ContactCounts;  

    SELECT c.Id AS ContactID, c.UniqueId AS ContactUniqueId, c.Name, c.Email, c.EmailScore, c.Phone, 
           c.WorkPhone, l.Location AS LeadLocation, d.Division AS LeadDivision, c.LeadTitle, 
           p.DecisionMakingPower, s.SeniorityLevel,
           CASE 
                WHEN c.LinkedInUrl IS NULL OR c.LinkedInUrl = '''' THEN NULL 
                WHEN LEFT(c.LinkedInUrl, 4) <> ''http'' THEN ''https://'' + c.LinkedInUrl 
                ELSE c.LinkedInUrl 
           END AS LinkedInUrl,
           c.Skills, c.PastCompanies, co.Id AS CompanyId, co.CompanyName, ci.CompanyIndustry, 
           cs.CompanySize, co.RevenueRange, co.CompanyProfileImageUrl, co.CompanyNAICSCode, 
           co.CompanySICCode, co.CompanyDescription, co.CompanyPhoneNumbers, 
           CASE 
                WHEN co.CompanyWebsite IS NULL OR co.CompanyWebsite = '''' THEN NULL 
                WHEN LEFT(co.CompanyWebsite, 4) <> ''http'' THEN ''https://'' + co.CompanyWebsite 
                ELSE co.CompanyWebsite 
           END AS CompanyWebsite, 
           CASE 
                WHEN co.CompanyFacebookPage IS NULL OR co.CompanyFacebookPage = '''' THEN NULL 
                WHEN LEFT(co.CompanyFacebookPage, 4) <> ''http'' THEN ''https://'' + co.CompanyFacebookPage 
                ELSE co.CompanyFacebookPage 
           END AS CompanyFacebookPage, 
           CASE 
                WHEN co.CompanyTwitterPage IS NULL OR co.CompanyTwitterPage = '''' THEN NULL 
                WHEN LEFT(co.CompanyTwitterPage, 4) <> ''http'' THEN ''https://'' + co.CompanyTwitterPage 
                ELSE co.CompanyTwitterPage 
           END AS CompanyTwitterPage, 
           CASE 
                WHEN co.CompanyProfileImageUrl IS NULL OR co.CompanyProfileImageUrl = '''' THEN NULL 
                WHEN LEFT(co.CompanyProfileImageUrl, 4) <> ''http'' THEN ''https://'' + co.CompanyProfileImageUrl 
                ELSE co.CompanyProfileImageUrl 
           END AS CompanyProfileImageUrl
    FROM Contacts c
    INNER JOIN LeadLocations l ON c.LeadLocationID = l.Id
    INNER JOIN LeadDivisions d ON c.LeadDivisionID = d.Id
    INNER JOIN DecisionMakingPowers p ON c.DecisionMakingPowerID = p.Id
    INNER JOIN SeniorityLevels s ON c.SeniorityLevelID = s.Id
    INNER JOIN Companies co ON c.CompanyID = co.Id
    INNER JOIN CompanyIndustries ci ON co.CompanyIndustryID = ci.Id
    LEFT JOIN CompanySizes cs ON co.CompanySizeID = cs.Id
    WHERE ' + @WhereClauseContacts + ' 
    AND ' + @WhereClauseCompanies + '
    ORDER BY c.Id
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
    ';

    -- Execute the dynamically built SQL
    EXEC sp_executesql @SQL, 
         N'@PageNumber INT, @PageSize INT, @CompanySize dbo.ContactFilterType READONLY, @LeadDivision dbo.ContactFilterType READONLY, @SeniorityLevel dbo.ContactFilterType READONLY, @EmailScore dbo.ContactFilterType READONLY, @CompanyIndustry dbo.ContactFilterType READONLY, @RevenueRange dbo.ContactFilterType READONLY',
         @PageNumber = @PageNumber, 
         @PageSize = @PageSize,
         @CompanySize = @CompanySize,
         @LeadDivision = @LeadDivision,
         @SeniorityLevel = @SeniorityLevel,
         @EmailScore = @EmailScore,
         @CompanyIndustry = @CompanyIndustry,
         @RevenueRange = @RevenueRange;
END;

Go
CREATE PROCEDURE [dbo].[ExportContactsToCsv]
    @CompanyName NVARCHAR(255) = NULL,
	@CompanySize dbo.ContactFilterType READONLY,
	@Name NVARCHAR(255) = NULL,  
    @Email NVARCHAR(255) = NULL, 
	@EmailScore dbo.ContactFilterType READONLY, 
	@LeadLocation NVARCHAR(255) = NULL, 
	@LeadDivision dbo.ContactFilterType READONLY,  
	@SeniorityLevel dbo.ContactFilterType READONLY, 
	@CompanySector NVARCHAR(255) = NULL, 
	@RevenueRange dbo.ContactFilterType READONLY,  
    @CompanyIndustry dbo.ContactFilterType READONLY,
    @LeadTitle NVARCHAR(255) = NULL,
    @CompanyNAICSCode INT = NULL,  
    @CompanySICCode INT = NULL, 
	@Keyword NVARCHAR(255) = NULL,
    @PerExportLimit INT = 10000
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP(@PerExportLimit) 
        c.Id AS ContactID, 
        c.CompanyID AS CompanyId,
        c.Name, 
        c.Email, 
        c.EmailScore, 
        c.Phone, 
        c.WorkPhone, 
        l.Location AS LeadLocation, 
        d.Division AS LeadDivision,
        c.LeadTitle, 
        p.DecisionMakingPower, 
        s.SeniorityLevel, 
		CASE 
            WHEN c.LinkedInUrl IS NULL OR c.LinkedInUrl = '' THEN NULL 
            WHEN LEFT(c.LinkedInUrl, 4) <> 'http' THEN 'https://' + c.LinkedInUrl 
            ELSE c.LinkedInUrl 
        END AS LinkedInUrl,
        c.Skills, 
        c.PastCompanies,
        co.Id AS CompanyId,
        co.CompanyName, 
        ci.CompanyIndustry, 
        cs.CompanySize, 
        co.RevenueRange, 
        co.CompanyProfileImageUrl, 
        co.CompanyNAICSCode, 
        co.CompanySICCode, 
        co.CompanyDescription, 
        co.CompanyPhoneNumbers, 
		CASE 
            WHEN co.CompanyLinkedinPage IS NULL OR co.CompanyLinkedinPage = '' THEN NULL 
            WHEN LEFT(co.CompanyLinkedinPage, 4) <> 'http' THEN 'https://' + co.CompanyLinkedinPage 
            ELSE co.CompanyLinkedinPage 
        END AS CompanyLinkedinPage,
	    CASE 
            WHEN co.CompanyTwitterPage IS NULL OR co.CompanyTwitterPage = '' THEN NULL 
            WHEN LEFT(co.CompanyTwitterPage, 4) <> 'http' THEN 'https://' + co.CompanyTwitterPage 
            ELSE co.CompanyTwitterPage 
        END AS CompanyTwitterPage,
	    CASE 
            WHEN co.CompanyFacebookPage IS NULL OR co.CompanyFacebookPage = '' THEN NULL 
            WHEN LEFT(co.CompanyFacebookPage, 4) <> 'http' THEN 'https://' + co.CompanyFacebookPage 
            ELSE co.CompanyFacebookPage 
        END AS CompanyFacebookPage,
	    CASE 
            WHEN co.CompanyProfileImageUrl IS NULL OR co.CompanyProfileImageUrl = '' THEN NULL 
            WHEN LEFT(co.CompanyProfileImageUrl, 4) <> 'http' THEN 'https://' + co.CompanyProfileImageUrl 
            ELSE co.CompanyProfileImageUrl 
        END AS CompanyProfileImageUrl,
	    CASE 
            WHEN co.CompanyWebsite IS NULL OR co.CompanyWebsite = '' THEN NULL 
            WHEN LEFT(co.CompanyWebsite, 4) <> 'http' THEN 'https://' + co.CompanyWebsite 
            ELSE co.CompanyWebsite 
        END AS CompanyWebsite
    FROM 
        Contacts c
    INNER JOIN LeadLocations l ON c.LeadLocationID = l.Id
    INNER JOIN LeadDivisions d ON c.LeadDivisionID = d.Id
    INNER JOIN DecisionMakingPowers p ON c.DecisionMakingPowerID = p.Id
    INNER JOIN SeniorityLevels s ON c.SeniorityLevelID = s.Id
    INNER JOIN Companies co ON c.CompanyID = co.Id
    INNER JOIN CompanyIndustries ci ON co.CompanyIndustryID = ci.Id
    left JOIN CompanySizes cs ON co.CompanySizeID = cs.Id
	INNER JOIN CompanySectors css ON co.CompanySectorId = css.Id
    WHERE
	    (@Name IS NULL OR c.Name LIKE '%' + @Name + '%')
        AND (@Email IS NULL OR c.Email LIKE '%' + @Email + '%')
		AND (@LeadTitle IS NULL OR c.LeadTitle LIKE '%' + @LeadTitle + '%')
        AND (@LeadLocation IS NULL OR c.LeadLocationID IN (SELECT l.Id FROM LeadLocations l WHERE l.Location LIKE '%' + @LeadLocation + '%'))
        AND (NOT EXISTS (SELECT 1 FROM @LeadDivision) OR c.LeadDivisionId IN (SELECT Value FROM @LeadDivision))
        AND (NOT EXISTS (SELECT 1 FROM @SeniorityLevel) OR c.SeniorityLevelID IN (SELECT Value FROM @SeniorityLevel))
        AND (NOT EXISTS (SELECT 1 FROM @EmailScore) OR c.EmailScore IN (SELECT Value FROM @EmailScore))		
		AND (@CompanyName IS NULL OR co.CompanyName LIKE '%' + @CompanyName + '%')
		AND (@Keyword IS NULL OR (co.keywords LIKE '%' + @Keyword + '%')) 
        AND (NOT EXISTS (SELECT 1 FROM @CompanyIndustry) OR co.CompanyIndustryID IN (SELECT Value FROM @CompanyIndustry))
        AND (NOT EXISTS (SELECT 1 FROM @CompanySize) OR co.CompanySizeID IN (SELECT Value FROM @CompanySize))
        AND (NOT EXISTS (SELECT 1 FROM @RevenueRange) OR co.RevenueRange IN (SELECT Value FROM @RevenueRange))
		AND (@CompanySector IS NULL OR co.CompanySectorId IN (SELECT s.Id FROM CompanySectors s WHERE s.CompanySector LIKE '%' + @CompanySector + '%'))
        AND (@CompanyNAICSCode IS NULL OR co.CompanyNAICSCode = @CompanyNAICSCode)
        AND (@CompanySICCode IS NULL OR co.CompanySICCode = @CompanySICCode)
    ORDER BY 
        c.Id
END;
Go
CREATE PROCEDURE dbo.GetCompanyProfileByCompanyId
    @CompanyId INT
AS
BEGIN
;WITH ContactCounts AS (
        SELECT 
            e.CompanyId,
            SUM(CASE WHEN sl.SeniorityLevel = 'Non-Manager' THEN 1 ELSE 0 END) AS TotalNonManager,
            SUM(CASE WHEN sl.SeniorityLevel = 'Manager' THEN 1 ELSE 0 END) AS TotalManagers,
            SUM(CASE WHEN sl.SeniorityLevel = 'Director' THEN 1 ELSE 0 END) AS TotalDirectors,
            SUM(CASE WHEN sl.SeniorityLevel = 'VP-Level' THEN 1 ELSE 0 END) AS TotalVPLevel,
            SUM(CASE WHEN sl.SeniorityLevel = 'C-Level' THEN 1 ELSE 0 END) AS TotalCLevel,
            MAX(CASE WHEN sl.SeniorityLevel = 'Non-Manager' THEN sl.Id END) AS SeniorityLevelNonManagerId,
            MAX(CASE WHEN sl.SeniorityLevel = 'Manager' THEN sl.Id END) AS SeniorityLevelManagerId,
            MAX(CASE WHEN sl.SeniorityLevel = 'Director' THEN sl.Id END) AS SeniorityLevelDirectorId,
            MAX(CASE WHEN sl.SeniorityLevel = 'VP-Level' THEN sl.Id END) AS SeniorityLevelVPId,
            MAX(CASE WHEN sl.SeniorityLevel = 'C-Level' THEN sl.Id END) AS SeniorityLevelCLevelId
        FROM Contacts e
        LEFT JOIN SeniorityLevels sl ON e.SeniorityLevelId = sl.Id 
        WHERE e.CompanyId = @CompanyId
        GROUP BY e.CompanyId
    )

    SELECT 
        c.Id AS CompanyId,
        c.CompanyName,
        c.CompanyDescription,
        c.CompanyPhoneNumbers,
        c.CompanyFoundedAt,
        TotalNonManager,
        TotalManagers,
        TotalDirectors,
        TotalVPLevel,
        TotalCLevel,
		CASE 
            WHEN c.CompanyLinkedinPage IS NULL OR c.CompanyLinkedinPage = '' THEN NULL 
            WHEN LEFT(c.CompanyLinkedinPage, 4) <> 'http' THEN 'https://' + c.CompanyLinkedinPage 
            ELSE c.CompanyLinkedinPage 
        END AS CompanyLinkedinPage,
	    CASE 
            WHEN c.CompanyTwitterPage IS NULL OR c.CompanyTwitterPage = '' THEN NULL 
            WHEN LEFT(c.CompanyTwitterPage, 4) <> 'http' THEN 'https://' + c.CompanyTwitterPage 
            ELSE c.CompanyTwitterPage 
        END AS CompanyTwitterPage,
	    CASE 
            WHEN c.CompanyFacebookPage IS NULL OR c.CompanyFacebookPage = '' THEN NULL 
            WHEN LEFT(c.CompanyFacebookPage, 4) <> 'http' THEN 'https://' + c.CompanyFacebookPage 
            ELSE c.CompanyFacebookPage 
        END AS CompanyFacebookPage,
	    CASE 
            WHEN c.CompanyProfileImageUrl IS NULL OR c.CompanyProfileImageUrl = '' THEN NULL 
            WHEN LEFT(c.CompanyProfileImageUrl, 4) <> 'http' THEN 'https://' + c.CompanyProfileImageUrl 
            ELSE c.CompanyProfileImageUrl 
        END AS CompanyProfileImageUrl,
	    CASE 
            WHEN c.CompanyWebsite IS NULL OR c.CompanyWebsite = '' THEN NULL 
            WHEN LEFT(c.CompanyWebsite, 4) <> 'http' THEN 'https://' + c.CompanyWebsite 
            ELSE c.CompanyWebsite 
        END AS CompanyWebsite,
        ci.CompanyIndustry,
        c.CompanySICCode,
        c.CompanyNAICSCode,
        c.CompanyLocationText,
        cs.CompanySize,
        c.RevenueRange,
        c.CompanyProductsServices,
		SeniorityLevelNonManagerId,
        SeniorityLevelManagerId,
        SeniorityLevelDirectorId,
        SeniorityLevelVPId,
        SeniorityLevelCLevelId
    FROM Companies c
    LEFT JOIN CompanySizes cs ON c.CompanySizeId = cs.Id
    LEFT JOIN CompanyIndustries ci ON c.CompanyIndustryId = ci.Id
    LEFT JOIN ContactCounts cc ON c.Id = cc.CompanyId
    WHERE c.Id = @CompanyId;
END
go