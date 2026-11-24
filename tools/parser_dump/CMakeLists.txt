set(SRCS parser_dump.cpp)
add_executable(p4c-dump-parser ${SRCS})
target_link_libraries(p4c-dump-parser frontend ir-generated ${P4C_LIBRARIES} ${P4C_LIB_DEPS})
install(TARGETS p4c-dump-parser RUNTIME DESTINATION ${P4C_RUNTIME_OUTPUT_DIRECTORY})
