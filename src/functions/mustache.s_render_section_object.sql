SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
/**
Internal aspect - not typically called directly
Handles sections based on objects

@module mustache/s_render_section_object
@see module:mustache/s_render

@param {nvarchar(max)} @template - the mustache template to render
@param {nvarchar(128)} @section - the name of the placeholder section which will be treated as a sub-document
@param {nvarchar(max)} @json - the JSON sub-object that will be used to render the sections and tags within the sub-document
@returns {nvarchar(max)} the @template with sliced sub-documents spliced into it

@date 2020-07-10
@author James Kelly
*/
CREATE OR ALTER FUNCTION mustache.s_render_section_object
(
	@template NVARCHAR(max),
	@section NVARCHAR(128),
	@json NVARCHAR(max)
)
RETURNS NVARCHAR(max)
AS
BEGIN
	DECLARE @doc			NVARCHAR(max)	= @template;
	DECLARE @docLen			INT				= LEN(@doc);

	DECLARE @sectionTagLen	INT				= LEN(@section) + 5;
	DECLARE @patOpen		NVARCHAR(256)	= CONCAT(N'%{{#', @section, N'}}%');
	DECLARE @patClose		NVARCHAR(256)	= CONCAT(N'%{{/', @section, N'}}%');
	DECLARE @patOpenOff		NVARCHAR(256)	= CONCAT(N'%{{^', @section, N'}}%');

	WHILE (@doc LIKE @patOpen)
	BEGIN
		DECLARE @sectionIdx		INT				= PATINDEX(@patOpen, @doc);
		DECLARE @sectionLen		INT				= PATINDEX(@patClose, @doc) + @sectionTagLen - @sectionIdx;

		DECLARE @blockIdx		INT				= @sectionIdx + @sectionTagLen;
		DECLARE @blockLen		INT				= @sectionLen - (2 * @sectionTagLen);
		DECLARE @blockDoc		NVARCHAR(max)	= SUBSTRING(@doc, @blockIdx, @blockLen);

		SET @blockDoc			= mustache.s_render(@blockDoc, @json);
		SET @doc				= STUFF(@doc, @sectionIdx, @sectionLen, @blockDoc);

		SET @sectionIdx			= PATINDEX(@patOpenOff, @doc);

		IF (@sectionIdx = 0)
		BEGIN CONTINUE; END

		SET @sectionLen			= PATINDEX(@patClose, @doc) + @sectionTagLen - @sectionIdx;
		SET @blockDoc			= N'';
		SET @doc				= STUFF(@doc, @sectionIdx, @sectionLen, COALESCE(@blockDoc, N''));
	END

	RETURN @doc;
END;