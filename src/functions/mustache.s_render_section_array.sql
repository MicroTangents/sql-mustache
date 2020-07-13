SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
/**
Internal aspect - not typically called directly
Handles array elements by slicing sub-documents, creating a templated
copy for each element in the array and then splicing the final
rendered sub-documents into the main

@module mustache/s_render_section_array
@see module:mustache/s_render

@param {nvarchar(max)} @template - the mustache template to render
@param {nvarchar(128)} @section - the name of the placeholder section which will be treated as a sub-document
@param {nvarchar(max)} @json - the JSON array that will be used to render the internal tags and ext of the sections within the sub-document
@returns {nvarchar(max)} the @template with any @tag's replaced with @value

@date 2020-07-10
@author James Kelly
*/
CREATE OR ALTER FUNCTION mustache.s_render_section_array
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

	DECLARE @tblEl			TABLE (
		val NVARCHAR(max),
		seq INT
	);

	DECLARE @elCnt			INT				= 0;

	INSERT INTO @tblEl (val, seq)
	SELECT x.[value] val, ROW_NUMBER() OVER(ORDER BY (SELECT 1)) seq
	FROM OPENJSON(@json, N'$') x;
	SET @elCnt				= @@ROWCOUNT;

	DECLARE @blockIdx		INT;
	DECLARE @blockLen		INT;
	DECLARE @blockDoc		NVARCHAR(max);

	WHILE (@doc LIKE @patOpen)
	BEGIN
		DECLARE @sectionIdx		INT				= PATINDEX(@patOpen, @doc);
		DECLARE @sectionLen		INT				= PATINDEX(@patClose, @doc) + @sectionTagLen - @sectionIdx;

		IF (@elCnt = 0)
		BEGIN
			SET @blockDoc		= N'';
		END
		ELSE
		BEGIN
			SET @blockIdx		= @sectionIdx + @sectionTagLen;
			SET @blockLen		= @sectionLen - (2 * @sectionTagLen);
			SET @blockDoc		= COALESCE(SUBSTRING(@doc, @blockIdx, @blockLen), N'');

			SELECT @blockDoc = STRING_AGG(
					mustache.s_render(@blockDoc, x.val)
					, N''
				) WITHIN GROUP (ORDER BY x.seq)
			FROM @tblEl x;
		END

		SET @doc				= STUFF(@doc, @sectionIdx, @sectionLen, COALESCE(@blockDoc, N''));

		SET @sectionIdx			= PATINDEX(@patOpenOff, @doc);
		
		IF (@sectionIdx = 0)
		BEGIN CONTINUE; END

		SET @sectionLen			= PATINDEX(@patClose, @doc) + @sectionTagLen - @sectionIdx;

		IF (@elCnt = 0)
		BEGIN
			SET @blockIdx			= @sectionIdx + @sectionTagLen;
			SET @blockLen			= @sectionLen - (2 * @sectionTagLen);
			SET @blockDoc			= COALESCE(SUBSTRING(@doc, @blockIdx, @blockLen), N'');
		END
		ELSE
		BEGIN
			SET @blockDoc		= N'';
		END

		SET @doc				= STUFF(@doc, @sectionIdx, @sectionLen, COALESCE(@blockDoc, N''));
	END

	RETURN @doc;
END;