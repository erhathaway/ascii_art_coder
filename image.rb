# require 'rubygems'
require 'rmagick'
require 'net/http'
# require 'json'
require 'open-uri'
require 'pry'


    def fetch_image(url)
      # LOGGER.debug "Open URL"
      file = open(url)

      img = Magick::ImageList.new
      # LOGGER.debug "Read blob"
      img.from_blob(file.read)
      # img.write('test.jpg')
    end

    def transform_image(img)
      # Owls tend to be brownish -> boost red and green channels
      # img = img.normalize_channel(Magick::RedChannel)
      # img = img.normalize_channel(Magick::GreenChannel)
      img = img.level_channel(Magick::RedChannel, black_point = 0, white_point = 50000, gamma = 2)
      img = img.level_channel(Magick::GreenChannel, black_point = 0, white_point = 50000, gamma = 2)

      # Reduce size and number of colors
      @size = 120
      img = img.resize_to_fit(@size, @size)
      img = img.posterize(10)

      img = img.quantize(5, Magick::GRAYColorspace)
    end

    # OUTPUT_ENTITIES = ['&#9608;', '&#9619;', '&#9617;', "&nbsp;"]
    # White and black, respectively
    # OUTPUT_ENTITIES = [0, 0000, 60000, 60000]
    OUTPUT_ENTITIES = [ " " , " " , "X", "X"]
    # OUTPUT_ENTITIES = [ "X" , "X" , " ", " "]

    def translate_image(img)
      # Export image as list of pixels
      pixels = img.export_pixels(0, 0, img.columns, img.rows, 'I')

      # pixels_new.write('hi.jpg')
      # Find all unique pixel values
      values = {}
      pixels.group_by do |x|
        values[x] = 0 unless values.has_key? x
      end
      i = 0
      # assign rank/indices to found values
      values.keys.sort.each {|key| values[key] = i; i = i + 1 }

      # Map pixel rank to html entities.
      a = pixels.map { |pixel| OUTPUT_ENTITIES[values[pixel]] }
      a
      # Dump picture to black and white
      # pixels_new = img.import_pixels(0, 0, img.columns, img.rows, 'I',a)
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

    def write_line(file_object, code_line, image_array, line_length)
      new_image_string = ""
      column_count = 0
      line_stop = false

      while column_count < line_length
        pixel = image_array.shift
        if pixel != " " and line_stop == false # or pixel != nil
          if code_line.length > 0
            a = " "
            while a == " " or a == "\n"
              a = code_line.shift
            end
            pixel = a
          else
            pixel = '#'
          end
        elsif pixel != " " and line_stop == true
          pixel = '#'
        else
          line_stop = true
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

    def replace(ruby_file, output_file, image_array, line_length)

      save_file = open(output_file, 'w')
      code_array = open(ruby_file, 'r') do |f|
        f.each_line do |line|
          code_line = line.split(/' '/)
          extra_code = true
          while extra_code
            extra_code = write_line(save_file, code_line, image_array, line_length)
          end
        end
      end
      save_file.close
    end


    # image = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSXSK2aQsa7H7xPoUtvLrwK-XoS3wBASrq0fP-IZ3CtrcgchdCg_w'
    # image = 'http://1.bp.blogspot.com/-aRsKTxxGdR8/U9lKeDKOaCI/AAAAAAAABSQ/47oVl8gby6U/s1600/Pringles+guy+snip.PNG'
    image = 'http://theartmad.com/wp-content/uploads/2015/04/Smiley-Face-2-300x300.jpg?timestamp=1435364618'
    # image = 'http://previews.123rf.com/images/rahultiwari3190/rahultiwari31901006/rahultiwari3190100600616/7266824-Computer-hand-cursor-for-click-in-middle-finger-vector-illustartion--Stock-Vector.jpg'
    image1 = fetch_image(image)
    # image1.ordered_dither(threshold_map='4x4') .write('test5.jpg')
    image2 = transform_image(image1).write('hi.jpg')
    image3 = translate_image(image2)
    # write('testfile.txt',image3,image2.columns)
    # puts image3

    # image1.posterize(10).quantize(5, Magick::GRAYColorspace).write('test2.jpg')

    replace('image.rb', 'testfile_code.txt', image3, image2.columns)


    # def replace(ruby_file, output_file, image_array, line_length)

    #   save_file = open(output_file, 'w')
    #   code_array = open(ruby_file, 'r') do |f|
    #     f.each_line do |line|
    #       code_line = line.split("")
    #   # binding.pry
    #       new_image_string = ""
    #       column_count = 0
    #       counter = 0
    #       while column_count < line_length
    #         pixel = image_array.shift
    #         if pixel != " " # or pixel != nil
    #           if code_line.length > 0
    #             a = " "
    #             while a == " " or a == "\n"
    #               a = code_line.shift
    #             end
    #             pixel = a
    #           else
    #             pixel = '#'
    #           end
    #         end
    #         if pixel == nil 
    #           pixel = " "
    #         end
    #         new_image_string += pixel
    #         column_count += 1
    #       end
    #         # binding.pry
    #       counter +=1
    #       save_file.write(new_image_string + "\n")
    #       column_count = 0
    #     end
    #   end
    #   save_file.close
    # end