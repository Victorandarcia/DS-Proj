class Preprocessor:
    """
    Class that calls the raw data file and convert it to a pandas DF.
    """

    def __init__(self, filepath):
        self.filepath = filepath  # complete path to excel file
        self.datadict = dict()  # contains all the dataframes inside a dictionary
        self.datastations = list()

    def read_file(self):
        """
        Call the xlsx file from the year we're interested.
        :return: dataframe in form of a dictionary
        """
        datasets = pd.read_excel(self.filepath, sheet_name=None)
        self.datadict = datasets

    def list_stations(self):
        """
        Obtain a list of all the tabs of the xlsx file.
        :return: update self.datastations values
        """
        self.datastations = list(self.datadict)

    def activate(self):
        """
        main method that reads and add the raw file to a DF and lists all of the stations on the file.
        :return: updates self.datadict and self.datastations values
        """
        Preprocessor.read_file(self)
        Preprocessor.list_stations(self)


class CorrectionTools(Preprocessor):
    """
    This class applies some datetime correction to the raw data, which is known to have some
    variances on its date and time format. It also checks for missing datetime values along the
    samples and add it if needed.

    The method that runs all of the other is called adjust_data(), nonetheless, you could run each method
    individually with the exception that you must introduce the station argument.
    """

    def __init__(self, filepath):
        super().__init__(filepath)
        self.fulldates_df = pd.DataFrame()
        self.date_column_name = 'FECHA'
        self.time_column_name = 'HORA'
        self.datetime_column_name = '{}{}'.format(self.date_column_name, self.time_column_name)
        self.parameters = ['CO', 'NO2', 'O3', 'PM10', 'SO2', 'TMP', 'HR', 'WS', 'WD']

    @staticmethod
    def hour_format_exchanger(hour):
        """
        Method that returns the specified argument on a datetime time format.
        :param hour:
        :return:
        """
        try:
            return hour.time()
        except AttributeError:
            return hour
        except ValueError:
            pass

    def combine_date_time(self, df):
        """
        Method that combines the new generated datetime date and datetime time objects to form a global
        datetime object.
        A new column with the name 'FECHAHORA' and the generated values will be added to the main Dataframe.
        :param df: Station specific dataframe in which the for loop is currently working.
        :return: the same df but with a new datetime column.
        """
        new_dt_column = list()

        for i in range(len(df)):
            new_dt_column.append(
                datetime.combine(
                    df[self.date_column_name][i],
                    df[self.time_column_name][i]
                )
            )

        # new datetime column
        df[self.datetime_column_name] = new_dt_column

        return df

    def datetime_format_exchanger(self, station):
        """
        Method that extracts and reformat the data and time from the raw files.
        :param station: Specific station of the main DF.
        :return: updates the date and time format on each station.
        """
        date_column_data = list()
        time_column_data = list()
        df = self.datadict[self.datastations[station]]

        for i in range(len(df)):
            date_column_data.append(
                df[self.date_column_name][i].date()
            )
            time_column_data.append(
                CorrectionTools.hour_format_exchanger(
                    df[self.time_column_name][i]
                )
            )

        # Dropping raw date and time columns
        df.drop(columns=self.date_column_name, inplace=True)
        df.drop(columns=self.time_column_name, inplace=True)

        # Appending formatted date and time columns to the DF
        df[self.date_column_name] = date_column_data
        df[self.time_column_name] = time_column_data
        df.dropna(axis=0, how='all', inplace=True)

        self.datadict[self.datastations[station]] = \
            CorrectionTools.combine_date_time(self, df)

    def complete_df_sample(self):
        """
        Creates a np.nan filled df with a datetime column that has as start_date the first day of the year
        and as end_date the last day of the year with a frequency of 1 hour between each datetime row.
        :return: update the fulldates_df value.
        """
        # It does not matter which integer we add to the index, we just want to obtain the year value in which
        # we will work to then create this complete dates df.

        year_value = self.datadict[self.datastations[0]][self.date_column_name][0]

        start_date = datetime(year_value.year, 1, 1, 0, 0, 0, 0)
        end_date = datetime(year_value.year, 12, 31, 23, 0, 0, 0)

        total_days = pd.date_range(start_date, end_date, freq="H")

        fulldates_df = pd.DataFrame({self.datetime_column_name: total_days})

        # fill all values with np.nan

        for contaminant in self.parameters:
            j = np.empty(len(fulldates_df))
            j[:] = np.nan
            fulldates_df[contaminant] = j

        self.fulldates_df = fulldates_df

    def merge_data(self, station):
        """
        Method that joins the station data df with the one with all the dates of the year but with nan values.

        :param station: Specific station of the main DF.
        :return: dataframe with the station data and with all the year dates values.
        """
        df = self.datadict[self.datastations[station]]
        fulldates_df = self.fulldates_df

        # Set the indexes of each df
        df.set_index(pd.to_datetime(df[self.datetime_column_name]), inplace=True)
        fulldates_df.set_index(pd.to_datetime(fulldates_df[self.datetime_column_name]), inplace=True)

        joined_dfs = fulldates_df.join(df, how="inner", rsuffix='', lsuffix='_other')

        # Temporary fix to avoid duplicates, drop_duplicates method not working
        joined_dfs = joined_dfs.drop(joined_dfs.loc[joined_dfs.index.duplicated()].index)

        # outer join to obtain the dates for the whole year
        joined_dfs = fulldates_df.join(joined_dfs, how="outer", rsuffix='', lsuffix='_other1')

        # we just select the parameters we want to keep from the joined_dfs

        self.datadict[self.datastations[station]] = joined_dfs[self.parameters]

    def adjust_data(self, modify_df=True):
        """
        Main method to be called.

        This method calls an .activate() function from Preprocessor parent class and imports the Xlsx
        data to a pandas DataFrame.
        Then, for every 'station' contained in the DF, some correction tools will be applied.


        The resulting DF can be accessed by calling the '.datadict' attribute on the object.
        :param modify_df: Bool
        """
        Preprocessor.activate(self)
        year_count = 0
        if modify_df:
            for station in range(len(self.datastations)):
                CorrectionTools.datetime_format_exchanger(self, station)
                if year_count == 0:
                    CorrectionTools.complete_df_sample(self)
                    year_count += 1
                CorrectionTools.merge_data(self, station)

    def adjust_station_data(self, station, modify_df=True):
        """
        Method to call if the user just want to obtain the modified df for a single or a list of stations.

        like the adjust_data method, this method calls an .activate() function from Preprocessor parent class and
        imports the Xlsx data to a pandas DataFrame.
        Then, for every 'station' contained in the DF, some correction tools will be applied.

        The problem here is that each station is accessed by a number on the self.datastations list.
        #TODO find a way to make this method valid for only a specific station

        The resulting DF can be accessed by calling the '.datadict' attribute on the object.
        :param modify_df:
        :param station:
        :return:
        """
        pass


class GroupByYears:
    """
    This class will concat various years of data into a single df which then can be classified into parameters.
    filepath input will be a list containing the path of the xlsx file.
    """

    def __init__(self):
        self.concat_datadict = dict()
        self.files_path = list()
        self.datastations = list()
        self.parameters = list()
        self.years_begin = None
        self.years_end = None
        self.date_column_name = 'FECHA'
        self.time_column_name = 'HORA'

    def add_date_and_time_cols(self):
        for station in self.datastations:
            self.concat_datadict[station][self.date_column_name] = [i.date() for i in
                                                                    self.concat_datadict[station].index]
            self.concat_datadict[station][self.time_column_name] = [i.time() for i in
                                                                    self.concat_datadict[station].index]

    def files_concat(self, xlsx_files_path):
        self.files_path = xlsx_files_path
        counter = 0
        if len(self.files_path) > 1:
            for year_filepath in self.files_path:
                CT_obj = CorrectionTools(year_filepath)
                CT_obj.adjust_data()
                if counter == 0:
                    self.concat_datadict = CT_obj.datadict
                    self.datastations = CT_obj.datastations
                    self.parameters = CT_obj.parameters
                    self.years_begin = self.concat_datadict[self.datastations[0]].index[0].year
                    counter += 1
                    continue
                else:
                    for station in CT_obj.datastations:
                        self.concat_datadict[station] = self.concat_datadict[station].append(CT_obj.datadict[station])
                        self.years_end = self.concat_datadict[self.datastations[0]].index[-1].year
                        # print(self.concat_datadict[station].append(CT_obj.datadict[station]))
        else:
            CT_obj = CorrectionTools(self.files_path[0])
            CT_obj.adjust_data()
            self.concat_datadict = CT_obj.datadict
            self.datastations = CT_obj.datastations
            self.parameters = CT_obj.parameters
            self.years_begin = self.concat_datadict[self.datastations[0]].index[0].year
            self.years_end = self.concat_datadict[self.datastations[0]].index[-1].year

        GroupByYears.add_date_and_time_cols(self)

    def export_to_csv(self, path):
        os.chdir(path)
        if not os.path.exists(r'Stations'):
            os.makedirs(r'Stations')
        dump_filepath = path + r'\Stations'
        os.chdir(dump_filepath)

        for station in self.concat_datadict:
            self.concat_datadict[station].to_csv(f'{self.years_begin}-{self.years_end}_{station}.csv')


class GroupByParameters(GroupByYears):
    """
    Group data by parameters such as CO, NO2, etc.

    """

    def __init__(self):
        super().__init__()
        self.all_parameters_df = dict()

    def add_date_and_time_cols(self):
        for parameter in self.parameters:
            self.all_parameters_df[parameter][self.date_column_name] = [i.date() for i in
                                                                        self.all_parameters_df[parameter].index]
            self.all_parameters_df[parameter][self.time_column_name] = [i.time() for i in
                                                                        self.all_parameters_df[parameter].index]


    def arrange_parameters(self, parameter):
        parameter_df = pd.DataFrame()
        for station in self.datastations:
            parameter_df[station] = self.concat_datadict[station][parameter]
        return parameter_df

    def get_all_parameters_df(self):
        for parameter in self.parameters:
            self.all_parameters_df[parameter] = GroupByParameters.arrange_parameters(self, parameter)
        GroupByParameters.add_date_and_time_cols(self)

    def export_to_csv(self, path):
        os.chdir(path)
        if not os.path.exists(r'Parameters'):
            os.makedirs(r'Parameters')
        dump_filepath = path + r'\Parameters'
        os.chdir(dump_filepath)

        for parameter in self.all_parameters_df:
            self.all_parameters_df[parameter].to_csv(f'{self.years_begin}-{self.years_end}_{parameter}.csv')


class OutliersRemovalTools:
    # Contar los datos anteriores y previos
    # drop to another df
    # count nules

    pass


# TODO: add comments on the GroupByParameters and GroupByYears class and methods
# TODO: Remove all values whose difference with the previous data is higher than 3stdev
# TODO: Create folder with all the values obtained so far without dropping rows with missing values
# TODO: Create folder with all the values obtained when dropping rows with missing values
# TODO: Perform EDA on the treated data


if __name__ == '__main__':
    '''Debugging code ahead'''
    import pandas as pd
    from datetime import datetime
    import numpy as np
    import os

    # get path to file
    folder_path_to_raw_data = r"C:\Users\victo\PycharmProjects\DataScienceProj\DS-Proj\Air_modelling\data\raw_data"
    folder_path_to_preprocessed_data = r"C:\Users\victo\PycharmProjects\DataScienceProj\DS-Proj\Air_modelling\data" \
                                       r"\preprocessed_data"
    os.chdir(folder_path_to_raw_data)
    files_path = os.listdir()

    # To just read the xslx file with pandas
    # y2017 = Preprocessor(files_path[1])
    # y2017.activate()

    # #To get only one xslx file with all missing datetime values
    # y2017_corr = CorrectionTools(files_path[1])
    # y2017_corr.adjust_data()

    # To concatenate all the xslx docs in one single table

    # all_years = GroupByYears()
    # all_years.files_concat(files_path)
    # all_years.export_to_csv(folder_path_to_preprocessed_data)
    # # all_years.concat_datadict #here's where all of the data is stored

    # To convert from station to parameters

    all_years_parameters = GroupByParameters()
    all_years_parameters.files_concat(files_path)
    all_years_parameters.get_all_parameters_df()
    all_years_parameters.export_to_csv(folder_path_to_preprocessed_data)
    # #all_years_parameters.all_parameters_df #here's where all of the converted data is stored
    #
