# -*- coding: utf-8 -*-

def main():
    # Step 1: 输入字符串
    input_data = "学生姓名,高数成绩,英语成绩,大物成绩;SanZhang,70,80,61;SiLi,86,77,81;WuWang,88,90,77;MingLi,60,77,81;MiWang,71,70,60;HaiLi,88,78,89;HeWang,70,90,80;LiWang,67,71,70"

    # Step 2: 将字符串转换为列表
    data_list = input_data.split(";")
    print("Step 2: 转换为列表")
    print(data_list)

    # Step 3: 将列表中的每个元素转换为子列表
    nested_list = [item.split(",") for item in data_list]
    print("\nStep 3: 转换为嵌套列表")
    print(nested_list)

    # Step 4: 将嵌套列表转换为字典列表
    headers = nested_list[0]  # 表头
    dict_list = []
    for row in nested_list[1:]:
        student_dict = {headers[i]: (int(row[i]) if i > 0 else row[i]) for i in range(len(headers))}
        dict_list.append(student_dict)

    print("\nStep 4: 转换为字典列表")
    print(dict_list)

    # Step 5: 排序算法设计
    print("\nStep 5: 排序结果")

    # (1) 按总分从高到低排序
    sorted_by_total_desc = sorted(dict_list, key=lambda x: x['高数成绩'] + x['英语成绩'] + x['大物成绩'], reverse=True)
    print("(1) 总分从高到低排序")
    print(sorted_by_total_desc)

    # (2) 按总分从低到高排序
    sorted_by_total_asc = sorted(dict_list, key=lambda x: x['高数成绩'] + x['英语成绩'] + x['大物成绩'])
    print("\n(2) 总分从低到高排序")
    print(sorted_by_total_asc)

    # (3) 按三门课成绩从高到低排序
    sorted_by_courses_desc = sorted(dict_list, key=lambda x: (x['高数成绩'], x['英语成绩'], x['大物成绩']), reverse=True)
    print("\n(3) 三门课成绩从高到低排序")
    print(sorted_by_courses_desc)

if __name__ == "__main__":
    main()