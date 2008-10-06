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



