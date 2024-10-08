USE [DBContacts]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblContacts](
	[Ids] [int] IDENTITY(1,1) NOT NULL,
	[id] [nvarchar](max) NULL,
	[company_id] [nvarchar](max) NULL,
	[name] [nvarchar](max) NULL,
	[email] [nvarchar](max) NULL,
	[email_score] [nvarchar](max) NULL,
	[phone] [nvarchar](max) NULL,
	[work_phone] [nvarchar](max) NULL,
	[lead_location] [nvarchar](max) NULL,
	[lead_division] [nvarchar](max) NULL,
	[lead_titles] [nvarchar](max) NULL,
	[decision_making_power] [nvarchar](max) NULL,
	[seniority_level] [nvarchar](max) NULL,
	[linkedin_url] [nvarchar](max) NULL,
	[skills] [nvarchar](max) NULL,
	[past_companies] [nvarchar](max) NULL,
	[company_name] [nvarchar](max) NULL,
	[company_size] [nvarchar](max) NULL,
	[company_website] [nvarchar](max) NULL,
	[company_phone_numbers] [nvarchar](max) NULL,
	[company_location_text] [nvarchar](max) NULL,
	[company_type] [nvarchar](max) NULL,
	[company_function] [nvarchar](max) NULL,
	[company_sector] [nvarchar](max) NULL,
	[company_industry] [nvarchar](max) NULL,
	[company_founded_at] [nvarchar](max) NULL,
	[company_funding_range] [nvarchar](max) NULL,
	[revenue_range] [nvarchar](max) NULL,
	[ebitda_range] [nvarchar](max) NULL,
	[company_facebook_page] [nvarchar](max) NULL,
	[company_twitter_page] [nvarchar](max) NULL,
	[company_linkedin_page] [nvarchar](max) NULL,
	[company_sic_code] [nvarchar](max) NULL,
	[company_naics_code] [nvarchar](max) NULL,
	[company_description] [nvarchar](max) NULL,
	[company_size_key] [nvarchar](max) NULL,
	[company_profile_image_url] [nvarchar](max) NULL,
	[company_products_services] [nvarchar](max) NULL,
	[keywords] [nvarchar](max) NULL,
 CONSTRAINT [PK_tblContacts] PRIMARY KEY CLUSTERED 
(
	[Ids] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tblSearchlimit]    Script Date: 9/26/2024 10:23:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblSearchlimit](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SearchLimitCount] [int] NOT NULL,
	[SearchLimitDate] [datetime2](7) NOT NULL,
	[SearchBy] [int] NOT NULL,
	[Email] [nvarchar](max) NOT NULL DEFAULT (N''),
	[password] [nvarchar](max) NOT NULL DEFAULT (N''),
 CONSTRAINT [PK_tblSearchlimit] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tblUserExport]    Script Date: 9/26/2024 10:23:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblUserExport](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ExportCount] [int] NOT NULL,
	[ExportDate] [datetime2](7) NOT NULL,
	[ExportBy] [int] NOT NULL,
 CONSTRAINT [PK_tblUserExport] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tblUsers]    Script Date: 9/26/2024 10:23:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblUsers](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Email] [nvarchar](max) NOT NULL,
	[password] [nvarchar](max) NOT NULL,
	[FirstName] [nvarchar](max) NOT NULL,
	[LastName] [nvarchar](max) NOT NULL,
	[ExportTodayLimit] [int] NOT NULL,
	[PerExportLimit] [int] NOT NULL,
	[isActive] [bit] NOT NULL,
	[isAdmin] [bit] NOT NULL,
	[searchlimit] [nvarchar](max) NULL,
 CONSTRAINT [PK_tblUsers] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

/****** Object:  StoredProcedure [dbo].[GetAllContacts]    Script Date: 9/26/2024 10:23:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetAllContacts]
        @company_size NVARCHAR(MAX) = NULL,
		@revenue_range NVARCHAR(MAX) = NULL,
        @seniority_level NVARCHAR(MAX) = NULL,
		@company_industry NVARCHAR(MAX) = NULL,
		@lead_divison NVARCHAR(MAX) = NULL,
		@email_score NVARCHAR(MAX) = NULL,
        @company_name  NVARCHAR(MAX) = NULL,
        @Keyword NVARCHAR(MAX) = NULL,
        @lead_titles  NVARCHAR(MAX) = NULL,
        @lead_location NVARCHAR(MAX) = NULL,
        @company_naics_code NVARCHAR(MAX) = NULL,
		@company_sic_code NVARCHAR(MAX) = NULL,
        @name NVARCHAR(MAX) = NULL,
        @email NVARCHAR(MAX) = NULL
       
       
    AS
    BEGIN
        SET NOCOUNT ON;
    
        SELECT TOP 1250 * FROM tblContacts WHERE
		   (@company_size IS NULL OR company_size IN (@company_size)) AND
		   (@revenue_range IS NULL OR @revenue_range IN (@revenue_range)) AND
		   (@seniority_level IS NULL OR seniority_level IN (@seniority_level)) AND
		   (@company_industry IS NULL OR company_industry IN (@company_industry)) AND
		   (@lead_divison IS NULL OR lead_division IN (@lead_divison)) AND
		   (@email_score IS NULL OR email_score IN (@email_score)) AND
		   (@company_name  IS NULL OR company_name  LIKE '%' + @company_name  + '%') AND
		   (@Keyword IS NULL OR company_sector LIKE '%' + @Keyword + '%') AND
		   (@lead_titles  IS NULL OR lead_titles  LIKE '%' + @lead_titles  + '%') AND
		   (@lead_location  IS NULL OR lead_location  LIKE '%' + @lead_location  + '%') AND
		   (@name IS NULL OR name LIKE '%' + @name + '%') AND
		   (@email IS NULL OR email LIKE '%' + @email + '%') AND
		   (@company_naics_code IS NULL OR company_naics_code LIKE '%' + @company_naics_code + '%')AND
		   (@company_sic_code IS NULL OR company_sic_code LIKE '%' + @company_sic_code + '%');
          
            

    END
GO
/****** Object:  StoredProcedure [dbo].[spDeleteSearchlimit]    Script Date: 9/26/2024 10:23:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[spDeleteSearchlimit]
@Id int
as
Begin
  Delete from tblSearchlimit where SearchBy = @Id
End

GO
/****** Object:  StoredProcedure [dbo].[spEmailUserExport]    Script Date: 9/26/2024 10:23:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[spEmailUserExport]
@Id int
as
Begin
  select * from tblUserExport where Id = @Id
End

GO
