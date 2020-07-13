SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
/**
Internal aspect - not typically called directly
Handles boolean values to switch sections on and off including inversions

@module mustache/s_render_section_bool
@see module:mustache/s_render

@param {nvarchar(max)} @template - the mustache template to render
@param {nvarchar(128)} @section - the name of the placeholder section which will be treated as a sub-document
@param {bit} @boolValue - the boolean value to determine if a section or its inversion (if any) are on or off
@returns {nvarchar(max)} the @template with any falsey @sections removed (or inverted)

@date 2020-07-10
@author James Kelly
*/
CREATE OR ALTER FUNCTION mustache.s_render_section_bool
(
	@template NVARCHAR(max),
	@section NVARCHAR(128),
	@boolVal BIT
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

	DECLARE @blockIdx		INT;
	DECLARE @blockLen		INT;
	DECLARE @blockDoc		NVARCHAR(max);

	WHILE (@doc LIKE @patOpen)
	BEGIN
		DECLARE @sectionIdx		INT				= PATINDEX(@patOpen, @doc);
		DECLARE @sectionLen		INT				= PATINDEX(@patClose, @doc) + @sectionTagLen - @sectionIdx;

		IF (@boolVal = 1)
		BEGIN
			SET @blockIdx		= @sectionIdx + @sectionTagLen;
			SET @blockLen		= @sectionLen - (2 * @sectionTagLen);
			SET @blockDoc		= COALESCE(SUBSTRING(@doc, @blockIdx, @blockLen), N'');
		END
		ELSE
		BEGIN
			SET @blockDoc		= N'';
		END

		SET @doc				= STUFF(@doc, @sectionIdx, @sectionLen, @blockDoc);

		SET @sectionIdx			= PATINDEX(@patOpenOff, @doc);

		IF (@sectionIdx = 0)
		BEGIN CONTINUE; END

		SET @sectionLen			= PATINDEX(@patClose, @doc) + @sectionTagLen - @sectionIdx;

		IF (@boolVal = 0)
		BEGIN
			SET @blockIdx		= @sectionIdx + @sectionTagLen;
			SET @blockLen		= @sectionLen - (2 * @sectionTagLen);
			SET @blockDoc		= COALESCE(SUBSTRING(@doc, @blockIdx, @blockLen), N'');
		END
		ELSE
		BEGIN
			SET @blockDoc		= N'';
		END

		SET @doc				= STUFF(@doc, @sectionIdx, @sectionLen, COALESCE(@blockDoc, N''));
	END

	RETURN @doc;
END;