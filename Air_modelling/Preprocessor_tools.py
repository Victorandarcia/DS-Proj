
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

    The method that runs all of the other is called ajust_data(), nonetheless, you could run each method
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
        end_date = datetime(year_value.year+1, 1, 1, 0, 0, 0, 0)

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

        joined_dfs = df.join(fulldates_df,
                             how="outer",
                             lsuffix='',
                             rsuffix='_other')

        joined_dfs_copy = joined_dfs.copy()
        joined_dfs_copy.drop_duplicates(keep='first', inplace=True)
        # we just select the parameters we want to keep from the joined_dfs

        self.datadict[self.datastations[station]] = joined_dfs_copy[self.parameters]

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


class GroupData:
    pass


if __name__ == '__main__':
    '''Debugging code ahead'''
    import pandas as pd
    from datetime import datetime, date, time, timedelta
    import numpy as np
    import os

    # get path to file
    folder_path = r'C:\Users\victo\PycharmProjects\DataScienceProj\DS-Proj\Air_modelling'
    data_path = r'\data\datos_2017.xlsx'
    process_file = folder_path + data_path

    # d_2016 = Preprocessor(process_file)
    # d_2016.activate()
    prueba = CorrectionTools(process_file)
    prueba.adjust_data()
