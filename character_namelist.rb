#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#-----------------------------------------------------------------------------
#	Convert from UnicodeData.txt to characters text
#	https://www.unicode.org/Public/12.1.0/ucd/UnicodeData.txt
#	
#	2019-11-20
#-----------------------------------------------------------------------------

=begin
https://www.unicode.org/reports/tr44/#UnicodeData.txt
CodePoint
Name
General_Category
Canonical_Combining_Class
Bidi_Class
Decomposition_Type, Decomposition_Mapping
Numeric_Type, Numeric_Value
Bidi_Mirrored
Unicode_1_Name (Obsolete as of 6.2.0)
ISO_Comment (Obsolete as of 5.2.0; Deprecated and Stabilized as of 6.0.0)
Simple_Uppercase_Mapping
Simple_Lowercase_Mapping
Simple_Titlecase_Mapping

0031; DIGIT ONE; Nd; 0; EN; ; 1; 1; 1; N; ; ; ; ;
0061; LATIN SMALL LETTER A;Ll;0;L;;;;;N;;;0041;;0041



=end


Encoding.default_external="utf-8"
#-----------------------------------------------------------------------------
#	
#-----------------------------------------------------------------------------
settings = {
	namelist_txt: "UnicodeData.txt",
	filename_out: "unicode_characters.txt"
}

CodepointCharacter = Struct.new( :codepoint, :name ) do
	def to_line
		"%s : %s : %c : %s" % [ "%08X" % self.codepoint, self.to_s_utf8, self.name == "<control>" ? " " : self.codepoint, self.name ]
	end

	# utf-8 バイト列文字列
	def to_s_utf8
		[ self.codepoint ].pack( "U" ).unpack( "C*" ).map{ |c| "%02X" % c }.join( "-" )
	end
end

CodepointRange = Struct.new( :codepoint_start, :codepoint_end, :name, :used ) do

	def output_left( start, fp )
		if start.nil?
			start = self.codepoint_start
		end
		( start .. self.codepoint_end ).each do |c|
			cc = CodepointCharacter.new( c, self.name )
			fp.puts( cc.to_line )
		end
	end

end


#-----------------------------------------------------------------------------
#	
#-----------------------------------------------------------------------------
def main( settings )
	namelist_txt = settings[ :namelist_txt ]
	filename_out = settings[ :filename_out ]
	codepoint_range = nil

	File.open( filename_out, "w" ) do |fp|
	
		File.foreach( namelist_txt ) do |line|
			if /^[0-9A-Fa-f]+;/ === line
				line_words = line.split(";")
			else
				next
			end
			( codepoint, name, general_category, canonical_combining_class, bidi_class, decomposition_type, decomposition_mapping, numeric_type, numeric_value, bidi_mirrored, unicode_1_name, iso_comment, simple_uppercase_mapping, simple_lowercase_mapping, simple_titlecase_mapping ) = line_words

			next if /Private Use|Surrogate|^\<reserved\>|^\<not a character\>/ === name

			codepoint = codepoint.hex
			if /^<(?<truename>[^>]*?), First>/ === name
				codepoint_range = CodepointRange.new( codepoint, codepoint, $~[:truename], false )
			elsif /^<(?<truename>[^>]*?), Last>/ === name
				codepoint_range.codepoint_end = codepoint
				codepoint_range.name = $~[:truename]
				codepoint_range.output_left( nil, fp )
				codepoint_range = nil
			else
				# codepoint 出力
				cc = CodepointCharacter.new( codepoint, name )
				fp.puts( cc.to_line )
			end
			
		end
	end
end

main( settings )