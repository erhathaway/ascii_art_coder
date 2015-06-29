require 'rmagick'
require 'open-uri'
require 'pry'


    def fetch_image(url)
      file = open(url)
      img = Magick::ImageList.new
      img.from_blob(file.read)
    end

    def transform_image(img)
      # enchance black / white levels
      img = img.level_channel(Magick::RedChannel, black_point = 0, white_point = 50000, gamma = 2)
      img = img.level_channel(Magick::GreenChannel, black_point = 0, white_point = 50000, gamma = 2)

      # Reduce size and number of colors
      @size = 120
      @size2 = 120
      img = img.resize_to_fit(@size, @size2)
      img = img.posterize(10)

      img = img.quantize(5, Magick::GRAYColorspace)
    end


    OUTPUT_ENTITIES = [ " " , " " , "#", "#"]

    def translate_image(img)
      # Export image as list of pixels
      pixels = img.export_pixels(0, 0, img.columns, img.rows, 'I')

      values = {}
      pixels.group_by do |x|
        values[x] = 0 unless values.has_key? x
      end
      i = 0
      # assign rank/indices to found values
      values.keys.sort.each {|key| values[key] = i; i = i + 1 }

      # Map pixel rank to html entities.
      pixels.map { |pixel| OUTPUT_ENTITIES[values[pixel]] }
    end    


    def write_file(filename, image_array, line_length)
      file = open(filename, 'w')
      while image_array.length > 0
        line = image_array.shift(line_length)
        line_string = ""
        line.each do |x|
          line_string += x.to_s
        end
        file.write(line_string + "\n")
      end
      file.close
    end    


    def write_other_line(file_object, code_line, image_array, line_length)
      file_object.write(code_line)
      if image_array.length > 0
        image_line = image_array.shift(line_length).join
      else
        image_line = '#'*line_length
      end
      file_object.write(image_line + "\n")
    end

    def write_line(file_object, code_line, image_array, line_length)
      new_image_string = ""
      column_count = 0
      line_stop = false
      code_end_flag = false

      #scan through image array until end of line
      while column_count < line_length

        #get image pixel sequentially
        pixel = image_array.shift

        #if pixel is not blank and end of code (aka line_stop) is not reached
        if pixel != " " and line_stop == false # or pixel != nil

          #if there is code, substitute it in for the pixel
          if code_line.length > 0
            a = " "
            #but don't take spaces or new lines
            while a == " " or a == "\n"
              a = code_line.shift
            end
            pixel = a

          #if there is not code, substitue in a comment symbol
          else
            pixel = '#'
          end

        #if the pixel is not blank and the end of code has been reached
        #substitute in a comment symbol
        elsif pixel != " " and line_stop == true
          pixel = '#'


        elsif code_end_flag == false
          line_stop = true
          code_end_flag = true
          code_line.unshift(new_image_string[-1])
          new_image_string.chop!
          new_image_string += '\\'
        end
        if pixel == nil 
          pixel = " "
        end
        new_image_string += pixel
        column_count += 1
      end

      file_object.write(new_image_string + "\n")

      if code_line.length > 0
        return code_line
      end
    end

    def replace(ruby_file, output_file, image_array, line_length, mode=1)

      save_file = open(output_file, 'w')
      code_array = open(ruby_file, 'r') do |f|
        f.each_line do |line|
          if mode ==0
            code_line = line.split("")
            extra_code = true
            while extra_code
              extra_code = write_line(save_file, code_line, image_array, line_length)
            end
          else
            write_other_line(save_file, line, image_array, line_length)
          end
        end
      end
      save_file.close
    end

    image = 'http://theartmad.com/wp-content/uploads/2015/04/Smiley-Face-2-300x300.jpg?timestamp=1435364618'

    image1 = fetch_image(image)
    image2 = transform_image(image1)
    image3 = translate_image(image2)

    replace('image.rb', 'test_file_code.rb', image3, image2.columns)

