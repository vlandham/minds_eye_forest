require 'inline'

class Array
  
  inline do |builder|
    builder.c <<-EOC
      static VALUE divide_each(VALUE value) {
        double divider = NUM2DBL(value);
        
        long i;
        for (i = 0; i < RARRAY(self)->len; i++) {
          double temp = NUM2DBL(RARRAY(self)->ptr[i]) / divider;
          VALUE temp2 = rb_float_new(temp);
          //printf("temp is %f \\n ", RARRAY(self)->ptr[i]);
          MEMCPY(RARRAY(self)->ptr+i,&temp2,VALUE,1);
          //RARRAY(self)->ptr[i] = &temp2;
          //printf("temp is %f \\n ", RARRAY(self)->ptr[i]);
        }
        return self;
      }
    EOC
  end
  
  inline do |builder|
    builder.c <<-EOC
     static void
     to_s_quick() {
       int i;
       float len = RARRAY(self)->len;
       if(len <= 0)
          rb_raise(rb_eTypeError, "array is empty");
       int buffer_size = 18;
       float total = len*buffer_size;
      
       char buf[buffer_size];
       
       VALUE str;
       str = rb_str_buf_new(total);
       for(i = 0; i < len;i++)
       {
         double value = RFLOAT(RARRAY(self)->ptr[i])->value;
         sprintf(buf, "%#.15f ", value);
        // printf("value = %s\\n", buf);
         //VALUE str_buf = rb_str_new2(buf);
         rb_str_buf_cat(str, buf, sizeof(buf));
       }
       rb_str_buf_cat(str, "\\n", 1);

     return str;
     }
     EOC
   end
  
   inline do |builder|
     builder.c <<-EOC
      static void
      to_matrix() {
        long i,j;
        int buffer_size = 18;
        float len1 = RARRAY(self)->len;
        if(len1 <= 0)
          rb_raise(rb_eTypeError, "matrix is empty");
        //printf("len1 = %f\\n", len1);
        float len2 = RARRAY(RARRAY(self)->ptr[0])->len;
        float total = len1*len2*buffer_size;
        //printf("total = %f\\n", total);
        char buf[buffer_size];
        VALUE str;
        str = rb_str_buf_new(total);

        for (i = 0; i < len1; i++) {
          VALUE *inner_array = RARRAY(self)->ptr[i];
          for(j = 0; j < len2;j++)
          {
            double value = RFLOAT(RARRAY(inner_array)->ptr[j])->value;
            sprintf(buf, "%#.15f ", value);
           // printf("value = %s\\n", buf);
            //VALUE str_buf = rb_str_new2(buf);
            rb_str_buf_cat(str, buf, sizeof(buf));
          }
          rb_str_buf_cat(str, "\\n", 1);
        }
        return str;
      }
    EOC
  end
  
   inline do |builder|
     builder.c <<-EOC
      static void
      to_matrix_fast() {
        long i,j,k;
        int buffer_size = 18;
        
        float len1 = RARRAY(self)->len;
        float len2 = RARRAY(RARRAY(self)->ptr[0])->len;
        
        int total = len1*len2*buffer_size;
        int index = 0;
        char buf[buffer_size];
        printf("total: %i\\n", total);
        char* large_buffer;
        large_buffer = ALLOC_N(char,total);
        
        for (i = 0; i < len1; i++) {
          VALUE *inner_array =  RARRAY(self)->ptr[i];
          //printf("len: %f\\n", RFLOAT(RARRAY(inner_array)->len));
          for(j = 0; j < len2;j++)
          {
            double value = RFLOAT(RARRAY(inner_array)->ptr[j])->value;
            sprintf(buf, "%#.15f ", value);
            
            for(k = 0;k< buffer_size;k++)
              {
              //  printf("index: %i\\n", index);
                large_buffer[index] = buf[k];
                index++;
              }
          }
          large_buffer[index] = '\\n';
         // printf("index: %i\\n", index);
          index++;
        }
        VALUE str;
        str = rb_str_buf_new2(large_buffer);
        free(large_buffer);
        return str;
      }
    EOC
  end
end






# old and ugly
# build the Array#average method in C using Ruby Objects
# inline do |builder|
#   builder.c_raw "
#     static VALUE divide_each(int argc, VALUE *argv, VALUE self) {
#       double divider = 65535.0;
#       
#       //divider = NUM2DBL(argv[0]);
#       long  i, len;
#       VALUE *arr = RARRAY(self)->ptr;
#       len = RARRAY(self)->len;
# 
#       for(i=0; i<len; i++) {
#         arr[i] = NUM2DBL(arr[i]);
#         printf(\"arr[i] is %f \\n\", NUM2DBL(arr[i]));
#       }
#      return arr;
#     }
#   "
# end



